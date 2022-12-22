module UploadCsv
  def self.import(file_path)
    report = 0
    conn = ApplicationRecord.connection

    conn.execute('begin;')

    conn.execute <<~SQL
      create temporary table _csv_appointment (
        doctor_last_name text,
        doctor_first_name text,
        national_provider_identifier text,
        patient_last_name text,
        patient_first_name text,
        universal_patient_identifier text,
        start_time text,
        end_time text
      ) on commit drop;
    SQL

    conn.raw_connection.copy_data("copy _csv_appointment from stdin with (format csv, delimiter ',', header true)") do
      conn.raw_connection.put_copy_data(File.read(file_path))
    end

    ApplicationRecord.transaction do
      report = conn.execute <<~SQL
        insert into people (first_name, last_name, created_at, updated_at)
        select distinct coalesce(doctor_first_name, 'UNKNOWN') as first_name,
                coalesce(doctor_last_name, 'UNKNOWN') as last_name, NOW(), NOW()
        from _csv_appointment
        union
        select distinct coalesce(patient_first_name, 'UNKNOWN') as first_name,
                coalesce(patient_last_name, 'UNKNOWN') as last_name, NOW(), NOW()
        from _csv_appointment
        ON CONFLICT DO NOTHING;

        insert into patients (upi, person_id, created_at, updated_at)
        select distinct COALESCE(LOWER(universal_patient_identifier), left(md5(random()::text), 9) || right(md5(random()::text), 9)), id, NOW(), NOW()
        from _csv_appointment csv
        inner join people p on p.first_name = csv.patient_first_name and p.last_name = csv.patient_last_name
        left outer join patients pt
          on p.id = pt.person_id
          and pt.upi = csv.universal_patient_identifier
        ON CONFLICT DO NOTHING;

        insert into doctors (npi, person_id, created_at, updated_at)
        select distinct COALESCE(LOWER(national_provider_identifier), floor(random() * 10000000000)::bigint::text), id, NOW(), NOW()
        from _csv_appointment csv
        inner join people p on p.first_name = csv.doctor_first_name and p.last_name = csv.doctor_last_name
        left outer join doctors d
          on p.id = d.person_id
          and p.first_name = csv.doctor_first_name
          and p.last_name = csv.doctor_last_name
          and
            case
            when LENGTH(csv.national_provider_identifier) < 10 then csv.national_provider_identifier || repeat('0', 10 - LENGTH(csv.national_provider_identifier))
            end = d.npi
            ON CONFLICT DO NOTHING;


        insert into appointments (patient_id, doctor_id, timerange, created_at, updated_at)
        select distinct p.person_id, d.person_id,
        tstzrange(to_timestamp(start_time, 'YYYY-MM-DD HH24:MI:SS'), to_timestamp(end_time, 'YYYY-MM-DD HH24:MI:SS'))
        , NOW(), NOW()
        from _csv_appointment csv
        left join patients p on
          p.upi = LOWER(csv.universal_patient_identifier)
        left join doctors d on
        d.npi = csv.national_provider_identifier
        --where to_timestamp(end_time, 'YYYY-MM-DD HH24:MI:SS') >= to_timestamp(start_time, 'YYYY-MM-DD HH24:MI:SS')
        where p.person_id <> d.person_id
        ON CONFLICT DO NOTHING;
      SQL

      conn.execute('commit;')
    end
    report
  end
end