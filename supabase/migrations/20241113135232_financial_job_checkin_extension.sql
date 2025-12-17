-- Location: supabase/migrations/20241113135232_financial_job_checkin_extension.sql
-- Schema Analysis: Extending existing sitter_pro_manager schema
-- Integration Type: Additive - adding financial dashboard and job check-in functionality
-- Dependencies: bookings, user_profiles tables (existing)

-- 1. Additional Types for new functionality
CREATE TYPE public.invoice_status AS ENUM ('draft', 'sent', 'paid', 'overdue', 'cancelled');
CREATE TYPE public.checkin_status AS ENUM ('checked_in', 'checked_out', 'in_progress');
CREATE TYPE public.task_status AS ENUM ('pending', 'completed', 'skipped');

-- 2. New Tables for Financial Dashboard and Job Check-in

-- Invoices for financial management
CREATE TABLE public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sitter_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    client_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    invoice_number TEXT NOT NULL UNIQUE,
    amount DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    status public.invoice_status DEFAULT 'draft'::public.invoice_status,
    issued_date DATE,
    due_date DATE,
    paid_date DATE,
    description TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Job check-ins for time tracking and service documentation
CREATE TABLE public.job_checkins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
    sitter_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    checkin_time TIMESTAMPTZ,
    checkout_time TIMESTAMPTZ,
    status public.checkin_status DEFAULT 'checked_in'::public.checkin_status,
    location_lat DECIMAL(10, 8), -- GPS latitude
    location_lng DECIMAL(11, 8), -- GPS longitude
    location_address TEXT,
    notes TEXT,
    photos JSONB, -- Array of photo URLs
    duration_minutes INTEGER, -- Calculated duration
    overtime_minutes INTEGER DEFAULT 0,
    total_earned DECIMAL(10,2), -- Calculated earnings for this session
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Task templates and completion tracking
CREATE TABLE public.checkin_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    checkin_id UUID REFERENCES public.job_checkins(id) ON DELETE CASCADE,
    service_type public.service_type NOT NULL,
    task_name TEXT NOT NULL,
    task_description TEXT,
    is_required BOOLEAN DEFAULT false,
    status public.task_status DEFAULT 'pending'::public.task_status,
    completed_at TIMESTAMPTZ,
    notes TEXT,
    photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Sitter settings and preferences
CREATE TABLE public.sitter_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sitter_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    default_hourly_rate DECIMAL(8,2),
    emergency_rate_multiplier DECIMAL(3,2) DEFAULT 1.5,
    timezone TEXT DEFAULT 'America/New_York',
    currency TEXT DEFAULT 'USD',
    auto_invoice BOOLEAN DEFAULT true,
    gps_tracking_enabled BOOLEAN DEFAULT true,
    notification_preferences JSONB DEFAULT '{"email": true, "sms": false, "push": true}'::jsonb,
    business_info JSONB, -- Tax ID, business name, etc.
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Service rates for different service types
CREATE TABLE public.service_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sitter_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    service_type public.service_type NOT NULL,
    base_rate DECIMAL(8,2) NOT NULL,
    is_flat_rate BOOLEAN DEFAULT false, -- true for flat rate, false for hourly
    weekend_multiplier DECIMAL(3,2) DEFAULT 1.2,
    holiday_multiplier DECIMAL(3,2) DEFAULT 1.5,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Indexes for performance
CREATE INDEX idx_invoices_sitter_id ON public.invoices(sitter_id);
CREATE INDEX idx_invoices_client_id ON public.invoices(client_id);
CREATE INDEX idx_invoices_status ON public.invoices(status);
CREATE INDEX idx_invoices_due_date ON public.invoices(due_date);
CREATE INDEX idx_job_checkins_booking_id ON public.job_checkins(booking_id);
CREATE INDEX idx_job_checkins_sitter_id ON public.job_checkins(sitter_id);
CREATE INDEX idx_job_checkins_status ON public.job_checkins(status);
CREATE INDEX idx_checkin_tasks_checkin_id ON public.checkin_tasks(checkin_id);
CREATE INDEX idx_checkin_tasks_status ON public.checkin_tasks(status);
CREATE INDEX idx_sitter_settings_sitter_id ON public.sitter_settings(sitter_id);
CREATE INDEX idx_service_rates_sitter_id ON public.service_rates(sitter_id);
CREATE INDEX idx_service_rates_service_type ON public.service_rates(service_type);

-- 4. Functions for calculations and automatic processes

-- Calculate job check-in earnings
CREATE OR REPLACE FUNCTION public.calculate_checkin_earnings(checkin_uuid UUID)
RETURNS DECIMAL(10,2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    duration INTEGER;
    base_rate DECIMAL(8,2);
    total DECIMAL(10,2);
BEGIN
    SELECT 
        jc.duration_minutes,
        COALESCE(sr.base_rate, b.hourly_rate, up.hourly_rate)
    INTO duration, base_rate
    FROM public.job_checkins jc
    JOIN public.bookings b ON jc.booking_id = b.id
    JOIN public.user_profiles up ON jc.sitter_id = up.id
    LEFT JOIN public.service_rates sr ON sr.sitter_id = jc.sitter_id 
        AND sr.service_type = b.service_type 
        AND sr.is_active = true
    WHERE jc.id = checkin_uuid;

    -- Calculate total: (duration in hours * hourly rate)
    total := (duration / 60.0) * base_rate;
    
    RETURN COALESCE(total, 0);
END;
$$;

-- Auto-generate invoice number
CREATE OR REPLACE FUNCTION public.generate_invoice_number(sitter_uuid UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    year_suffix TEXT;
    counter INTEGER;
BEGIN
    -- Get current year
    year_suffix := EXTRACT(YEAR FROM CURRENT_DATE)::TEXT;
    
    -- Get next sequential number for this sitter
    SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM '\d+$') AS INTEGER)), 0) + 1
    INTO counter
    FROM public.invoices
    WHERE sitter_id = sitter_uuid 
    AND invoice_number LIKE 'INV-' || year_suffix || '-%';
    
    RETURN 'INV-' || year_suffix || '-' || LPAD(counter::TEXT, 4, '0');
END;
$$;

-- 5. Enable RLS for new tables
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checkin_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sitter_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_rates ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies following established patterns

-- Pattern 7: Invoice access (sitter or client can access)
CREATE OR REPLACE FUNCTION public.can_access_invoice(invoice_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.invoices
    WHERE id = invoice_uuid 
    AND (sitter_id = auth.uid() OR client_id = auth.uid())
)
$$;

CREATE POLICY "users_access_own_invoices"
ON public.invoices
FOR ALL
TO authenticated
USING (public.can_access_invoice(id))
WITH CHECK (public.can_access_invoice(id));

-- Pattern 2: Simple user ownership for job check-ins
CREATE POLICY "sitters_manage_own_checkins"
ON public.job_checkins
FOR ALL
TO authenticated
USING (sitter_id = auth.uid())
WITH CHECK (sitter_id = auth.uid());

-- Pattern 7: Check-in task access (via job check-in relationship)
CREATE OR REPLACE FUNCTION public.can_access_checkin_task(task_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.checkin_tasks ct
    JOIN public.job_checkins jc ON ct.checkin_id = jc.id
    WHERE ct.id = task_uuid AND jc.sitter_id = auth.uid()
)
$$;

CREATE POLICY "sitters_access_own_checkin_tasks"
ON public.checkin_tasks
FOR ALL
TO authenticated
USING (public.can_access_checkin_task(id))
WITH CHECK (public.can_access_checkin_task(id));

-- Pattern 2: Simple user ownership for settings
CREATE POLICY "sitters_manage_own_settings"
ON public.sitter_settings
FOR ALL
TO authenticated
USING (sitter_id = auth.uid())
WITH CHECK (sitter_id = auth.uid());

-- Pattern 2: Simple user ownership for service rates
CREATE POLICY "sitters_manage_own_rates"
ON public.service_rates
FOR ALL
TO authenticated
USING (sitter_id = auth.uid())
WITH CHECK (sitter_id = auth.uid());

-- 7. Mock Data for new functionality
DO $$
DECLARE
    existing_sitter_id UUID;
    existing_client_id UUID;
    existing_booking_id UUID;
    checkin1_id UUID := gen_random_uuid();
    checkin2_id UUID := gen_random_uuid();
    invoice1_id UUID := gen_random_uuid();
    settings_id UUID := gen_random_uuid();
BEGIN
    -- Get existing user and booking IDs from the existing schema
    SELECT id INTO existing_sitter_id FROM public.user_profiles WHERE role = 'sitter' LIMIT 1;
    SELECT id INTO existing_client_id FROM public.user_profiles WHERE role = 'client' LIMIT 1;
    SELECT id INTO existing_booking_id FROM public.bookings LIMIT 1;

    -- Only proceed if we have existing data
    IF existing_sitter_id IS NOT NULL AND existing_booking_id IS NOT NULL THEN
        -- Create sitter settings
        INSERT INTO public.sitter_settings (id, sitter_id, default_hourly_rate, timezone, currency, gps_tracking_enabled, notification_preferences, business_info)
        VALUES (settings_id, existing_sitter_id, 25.00, 'America/Chicago', 'USD', true, 
                '{"email": true, "sms": true, "push": true}'::jsonb,
                '{"business_name": "Alex Thompson Childcare Services", "tax_id": "12-3456789"}'::jsonb);

        -- Create service rates
        INSERT INTO public.service_rates (sitter_id, service_type, base_rate, is_flat_rate, weekend_multiplier, holiday_multiplier)
        VALUES 
            (existing_sitter_id, 'babysitting'::public.service_type, 25.00, false, 1.2, 1.5),
            (existing_sitter_id, 'pet_sitting'::public.service_type, 20.00, false, 1.1, 1.3),
            (existing_sitter_id, 'house_sitting'::public.service_type, 150.00, true, 1.0, 1.2);

        -- Create job check-ins
        INSERT INTO public.job_checkins (id, booking_id, sitter_id, checkin_time, checkout_time, status, location_lat, location_lng, location_address, notes, duration_minutes, total_earned)
        VALUES 
            (checkin1_id, existing_booking_id, existing_sitter_id, 
             CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '30 minutes', 
             'checked_out'::public.checkin_status, 39.7817, -89.6501, 
             '456 Oak Street, Springfield, IL 62702', 
             'Great session with the kids. Emma helped me read to Jake.', 90, 37.50),
            (checkin2_id, existing_booking_id, existing_sitter_id, 
             CURRENT_TIMESTAMP - INTERVAL '4 hours', NULL, 
             'in_progress'::public.checkin_status, 39.7817, -89.6501, 
             '789 Pine Avenue, Springfield, IL 62703', 
             'Currently walking Max around the neighborhood.', NULL, NULL);

        -- Create check-in tasks
        INSERT INTO public.checkin_tasks (checkin_id, service_type, task_name, task_description, is_required, status, completed_at)
        VALUES 
            (checkin1_id, 'babysitting'::public.service_type, 'Safety Check', 'Verify all doors and windows are secure', true, 'completed'::public.task_status, CURRENT_TIMESTAMP - INTERVAL '1 hour 45 minutes'),
            (checkin1_id, 'babysitting'::public.service_type, 'Meal Preparation', 'Prepare healthy snacks or meals as requested', false, 'completed'::public.task_status, CURRENT_TIMESTAMP - INTERVAL '1 hour 15 minutes'),
            (checkin1_id, 'babysitting'::public.service_type, 'Activity Time', 'Engage children in appropriate activities', true, 'completed'::public.task_status, CURRENT_TIMESTAMP - INTERVAL '1 hour'),
            (checkin2_id, 'pet_sitting'::public.service_type, 'Walk Pet', 'Take pet for required walk', true, 'completed'::public.task_status, CURRENT_TIMESTAMP - INTERVAL '3 hours 30 minutes'),
            (checkin2_id, 'pet_sitting'::public.service_type, 'Feed Pet', 'Provide food and fresh water', true, 'pending'::public.task_status, NULL);

        -- Create invoices
        IF existing_client_id IS NOT NULL THEN
            INSERT INTO public.invoices (id, sitter_id, client_id, booking_id, invoice_number, amount, tax_amount, total_amount, status, issued_date, due_date, description)
            VALUES 
                (invoice1_id, existing_sitter_id, existing_client_id, existing_booking_id, 
                 'INV-2024-0001', 125.00, 12.50, 137.50, 'sent'::public.invoice_status, 
                 CURRENT_DATE - INTERVAL '3 days', CURRENT_DATE + INTERVAL '27 days', 
                 'Babysitting services - 5 hours at $25/hour');
        END IF;
    END IF;
END $$;