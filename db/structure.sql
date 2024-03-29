SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: enum_status_appointment; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_status_appointment AS ENUM (
    'ok',
    'error'
);


--
-- Name: enum_status_doctor; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.enum_status_doctor AS ENUM (
    'active',
    'inactive'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: appointments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appointments (
    id bigint NOT NULL,
    patient_id bigint NOT NULL,
    doctor_id bigint NOT NULL,
    status public.enum_status_appointment DEFAULT 'ok'::public.enum_status_appointment NOT NULL,
    timerange tstzrange NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT check_if_dr_and_patient_are_different CHECK (((doctor_id <> patient_id) OR (status <> 'ok'::public.enum_status_appointment))),
    CONSTRAINT check_if_empty CHECK ((NOT isempty(timerange)))
);


--
-- Name: appointments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.appointments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.appointments_id_seq OWNED BY public.appointments.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: doctors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.doctors (
    npi character varying NOT NULL,
    status public.enum_status_doctor DEFAULT 'active'::public.enum_status_doctor NOT NULL,
    person_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT npi_check CHECK (((npi)::text ~ '^[0-9]{10}$'::text))
);


--
-- Name: doctors_person_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.doctors_person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doctors_person_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.doctors_person_id_seq OWNED BY public.doctors.person_id;


--
-- Name: patients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patients (
    upi character varying NOT NULL,
    person_id bigint NOT NULL,
    doctor_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT check_if_dr_and_person_are_different CHECK ((doctor_id <> person_id)),
    CONSTRAINT upi_check CHECK (((upi)::text ~ '^[a-z0-9]{18}$'::text))
);


--
-- Name: patients_person_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.patients_person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: patients_person_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.patients_person_id_seq OWNED BY public.patients.person_id;


--
-- Name: people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.people (
    id bigint NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT chk_rails_17659736c4 CHECK (((last_name)::text ~ '\S'::text)),
    CONSTRAINT chk_rails_1a5fdbc022 CHECK (((first_name)::text ~ '\S'::text))
);


--
-- Name: people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.people_id_seq OWNED BY public.people.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: appointments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments ALTER COLUMN id SET DEFAULT nextval('public.appointments_id_seq'::regclass);


--
-- Name: doctors person_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doctors ALTER COLUMN person_id SET DEFAULT nextval('public.doctors_person_id_seq'::regclass);


--
-- Name: patients person_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients ALTER COLUMN person_id SET DEFAULT nextval('public.patients_person_id_seq'::regclass);


--
-- Name: people id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.people ALTER COLUMN id SET DEFAULT nextval('public.people_id_seq'::regclass);


--
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: doctors doctors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT doctors_pkey PRIMARY KEY (person_id);


--
-- Name: appointments index_appointments_timerange_exclude_no_overlap_doctor_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT index_appointments_timerange_exclude_no_overlap_doctor_id EXCLUDE USING gist (timerange WITH &&, doctor_id WITH =) WHERE ((status = 'ok'::public.enum_status_appointment));


--
-- Name: appointments index_appointments_timerange_exclude_no_overlap_patient_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT index_appointments_timerange_exclude_no_overlap_patient_id EXCLUDE USING gist (timerange WITH &&, patient_id WITH =) WHERE ((status = 'ok'::public.enum_status_appointment));


--
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (person_id);


--
-- Name: people people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: check_upi_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX check_upi_unique ON public.patients USING btree (upi);


--
-- Name: index_appointments_on_doctor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointments_on_doctor_id ON public.appointments USING btree (doctor_id);


--
-- Name: index_appointments_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointments_on_patient_id ON public.appointments USING btree (patient_id);


--
-- Name: index_doctors_on_npi; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_doctors_on_npi ON public.doctors USING btree (npi);


--
-- Name: index_doctors_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_doctors_on_person_id ON public.doctors USING btree (person_id);


--
-- Name: index_patients_on_doctor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_doctor_id ON public.patients USING btree (doctor_id);


--
-- Name: index_patients_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_person_id ON public.patients USING btree (person_id);


--
-- Name: index_people_on_first_name_and_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_people_on_first_name_and_last_name ON public.people USING btree (first_name, last_name);


--
-- Name: index_unique_patient_doctor_timerange; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_unique_patient_doctor_timerange ON public.appointments USING btree (patient_id, doctor_id, timerange);


--
-- Name: doctors fk_rails_1046c05cde; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT fk_rails_1046c05cde FOREIGN KEY (person_id) REFERENCES public.people(id);


--
-- Name: appointments fk_rails_8db8e1e8a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT fk_rails_8db8e1e8a5 FOREIGN KEY (doctor_id) REFERENCES public.doctors(person_id) ON DELETE CASCADE;


--
-- Name: patients fk_rails_9739853ad1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT fk_rails_9739853ad1 FOREIGN KEY (doctor_id) REFERENCES public.doctors(person_id) ON DELETE SET NULL;


--
-- Name: appointments fk_rails_c63da04ab4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT fk_rails_c63da04ab4 FOREIGN KEY (patient_id) REFERENCES public.patients(person_id) ON DELETE CASCADE;


--
-- Name: patients fk_rails_f10cf91b9e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT fk_rails_f10cf91b9e FOREIGN KEY (person_id) REFERENCES public.people(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20221114125656'),
('20221114130035'),
('20221114130911'),
('20221114134112');


