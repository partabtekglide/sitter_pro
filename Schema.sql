-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.bookings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  client_id uuid,
  sitter_id uuid,
  service_type USER-DEFINED NOT NULL,
  start_date date NOT NULL,
  end_date date,
  start_time time without time zone NOT NULL,
  end_time time without time zone,
  hourly_rate numeric NOT NULL,
  total_amount numeric,
  duration_hours integer,
  special_instructions text,
  address text NOT NULL,
  status USER-DEFINED DEFAULT 'pending'::booking_status,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT bookings_pkey PRIMARY KEY (id),
  CONSTRAINT bookings_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id),
  CONSTRAINT bookings_sitter_id_fkey FOREIGN KEY (sitter_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.checkin_tasks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  checkin_id uuid,
  service_type USER-DEFINED NOT NULL,
  task_name text NOT NULL,
  task_description text,
  is_required boolean DEFAULT false,
  status USER-DEFINED DEFAULT 'pending'::task_status,
  completed_at timestamp with time zone,
  notes text,
  photo_url text,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT checkin_tasks_pkey PRIMARY KEY (id),
  CONSTRAINT checkin_tasks_checkin_id_fkey FOREIGN KEY (checkin_id) REFERENCES public.job_checkins(id)
);
CREATE TABLE public.clients (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid DEFAULT auth.uid(),
  emergency_contact_name text,
  emergency_contact_phone text,
  special_instructions text,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  full_name text,
  phone text,
  email text,
  address text,
  avatar_url text,
  preferred_rate numeric DEFAULT 25.00,
  CONSTRAINT clients_pkey PRIMARY KEY (id),
  CONSTRAINT clients_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.communications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sender_id uuid,
  receiver_id uuid,
  booking_id uuid,
  type USER-DEFINED NOT NULL,
  subject text,
  content text,
  is_read boolean DEFAULT false,
  call_duration integer,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT communications_pkey PRIMARY KEY (id),
  CONSTRAINT communications_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.user_profiles(id),
  CONSTRAINT communications_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.user_profiles(id),
  CONSTRAINT communications_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id)
);
CREATE TABLE public.invoices (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sitter_id uuid,
  client_id uuid,
  booking_id uuid,
  invoice_number text NOT NULL UNIQUE,
  amount numeric NOT NULL,
  tax_amount numeric DEFAULT 0,
  total_amount numeric NOT NULL,
  status USER-DEFINED DEFAULT 'draft'::invoice_status,
  issued_date date,
  due_date date,
  paid_date date,
  description text,
  notes text,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT invoices_pkey PRIMARY KEY (id),
  CONSTRAINT invoices_sitter_id_fkey FOREIGN KEY (sitter_id) REFERENCES public.user_profiles(id),
  CONSTRAINT invoices_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.user_profiles(id),
  CONSTRAINT invoices_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id)
);
CREATE TABLE public.job_checkins (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  booking_id uuid,
  sitter_id uuid,
  checkin_time timestamp with time zone,
  checkout_time timestamp with time zone,
  status USER-DEFINED DEFAULT 'checked_in'::checkin_status,
  location_lat numeric,
  location_lng numeric,
  location_address text,
  notes text,
  photos jsonb,
  duration_minutes integer,
  overtime_minutes integer DEFAULT 0,
  total_earned numeric,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT job_checkins_pkey PRIMARY KEY (id),
  CONSTRAINT job_checkins_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id),
  CONSTRAINT job_checkins_sitter_id_fkey FOREIGN KEY (sitter_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  booking_id uuid,
  type USER-DEFINED NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  is_read boolean DEFAULT false,
  actionable boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id),
  CONSTRAINT notifications_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id)
);
CREATE TABLE public.pets_kids (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  client_id uuid,
  name text NOT NULL,
  type text NOT NULL,
  age integer,
  special_notes text,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pets_kids_pkey PRIMARY KEY (id),
  CONSTRAINT pets_kids_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id)
);
CREATE TABLE public.reviews (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  booking_id uuid,
  reviewer_id uuid,
  reviewee_id uuid,
  rating integer CHECK (rating >= 1 AND rating <= 5),
  comment text,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT reviews_pkey PRIMARY KEY (id),
  CONSTRAINT reviews_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id),
  CONSTRAINT reviews_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES public.user_profiles(id),
  CONSTRAINT reviews_reviewee_id_fkey FOREIGN KEY (reviewee_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.service_rates (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sitter_id uuid,
  service_type USER-DEFINED NOT NULL,
  base_rate numeric NOT NULL,
  is_flat_rate boolean DEFAULT false,
  weekend_multiplier numeric DEFAULT 1.2,
  holiday_multiplier numeric DEFAULT 1.5,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT service_rates_pkey PRIMARY KEY (id),
  CONSTRAINT service_rates_sitter_id_fkey FOREIGN KEY (sitter_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.sitter_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sitter_id uuid,
  default_hourly_rate numeric,
  emergency_rate_multiplier numeric DEFAULT 1.5,
  timezone text DEFAULT 'America/New_York'::text,
  currency text DEFAULT 'USD'::text,
  auto_invoice boolean DEFAULT true,
  gps_tracking_enabled boolean DEFAULT true,
  notification_preferences jsonb DEFAULT '{"sms": false, "push": true, "email": true}'::jsonb,
  business_info jsonb,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT sitter_settings_pkey PRIMARY KEY (id),
  CONSTRAINT sitter_settings_sitter_id_fkey FOREIGN KEY (sitter_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.user_profiles (
  id uuid NOT NULL,
  email text NOT NULL UNIQUE,
  full_name text NOT NULL,
  phone text,
  address text,
  avatar_url text,
  role USER-DEFINED DEFAULT 'client'::user_role,
  bio text,
  hourly_rate numeric,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT user_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);