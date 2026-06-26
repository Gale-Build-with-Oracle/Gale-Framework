# Doctor Theme Component Patterns (shadcn/ui + Tailwind v4)

Healthcare and clinic component patterns for YD branded apps. Keep surfaces neutral, use navy `#1B2D5B` for clinical hierarchy, blue `#2B6CB0` for primary actions and normal active states, and red `#D42F2F` only for alerts, critical values, or blocked care.

## Required shadcn components

```bash
npx shadcn@latest add avatar badge button card form input label progress select separator skeleton table tabs textarea tooltip
```

## Shared Helpers

Use the same state helpers across clinic components so status color does not drift between cards, tables, and timelines.

```tsx
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";
import {
  AlertTriangle,
  CalendarCheck,
  CheckCircle2,
  ClipboardList,
  FlaskConical,
  HeartPulse,
  Pill,
  Stethoscope,
  UserRound,
} from "lucide-react";

export const yd = {
  navy: "#1B2D5B",
  blue: "#2B6CB0",
  red: "#D42F2F",
};

type Tone = "normal" | "active" | "muted" | "watch" | "alert";

export function toneClass(tone: Tone) {
  return {
    normal: "border-[#2B6CB0]/25 bg-[#2B6CB0]/10 text-[#1B2D5B]",
    active: "border-[#2B6CB0] bg-[#2B6CB0] text-white",
    muted: "border-border bg-muted text-muted-foreground",
    watch: "border-amber-200 bg-amber-50 text-amber-800",
    alert: "border-[#D42F2F]/30 bg-[#D42F2F]/10 text-[#D42F2F]",
  }[tone];
}

export function ClinicalBadge({
  children,
  tone = "normal",
}: {
  children: React.ReactNode;
  tone?: Tone;
}) {
  return (
    <Badge variant="outline" className={cn("rounded-md font-medium capitalize", toneClass(tone))}>
      {children}
    </Badge>
  );
}

export function EmptyClinicState({
  icon: Icon = ClipboardList,
  title,
  description,
}: {
  icon?: React.ComponentType<{ className?: string }>;
  title: string;
  description: string;
}) {
  return (
    <div className="flex min-h-36 flex-col items-center justify-center rounded-lg border border-dashed bg-muted/20 p-6 text-center">
      <Icon className="mb-3 size-9 text-[#1B2D5B]/35" />
      <p className="text-sm font-semibold text-[#1B2D5B]">{title}</p>
      <p className="mt-1 max-w-xs text-sm text-muted-foreground">{description}</p>
    </div>
  );
}

export function FieldSkeleton({ className }: { className?: string }) {
  return <Skeleton className={cn("h-4 rounded-md", className)} />;
}
```

## Patient Card

Use for patient search results, waiting room lists, and side panels. Put the patient identity first, then a concise clinical status and last visit metadata.

```tsx
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Card, CardContent } from "@/components/ui/card";
import { CalendarClock, UserRound } from "lucide-react";

type PatientStatus = "active" | "waiting" | "critical" | "discharged";

interface PatientCardData {
  id: string;
  name: string;
  patientId: string;
  avatarUrl?: string;
  status: PatientStatus;
  lastVisit: string;
}

function patientTone(status: PatientStatus) {
  if (status === "critical") return "alert";
  if (status === "waiting") return "watch";
  if (status === "discharged") return "muted";
  return "normal";
}

export function PatientCardSkeleton() {
  return (
    <Card className="shadow-sm">
      <CardContent className="flex items-center gap-4 p-4">
        <Skeleton className="size-12 rounded-full" />
        <div className="min-w-0 flex-1 space-y-2">
          <FieldSkeleton className="h-5 w-40" />
          <FieldSkeleton className="w-24" />
        </div>
        <FieldSkeleton className="h-6 w-20 rounded-md" />
      </CardContent>
    </Card>
  );
}

export function PatientCardEmpty() {
  return (
    <EmptyClinicState
      icon={UserRound}
      title="No patient selected"
      description="Search by patient name, national ID, or clinic ID to show a patient card."
    />
  );
}

export function PatientCard({ patient, isLoading }: { patient?: PatientCardData; isLoading?: boolean }) {
  if (isLoading) return <PatientCardSkeleton />;
  if (!patient) return <PatientCardEmpty />;

  return (
    <Card className="border shadow-sm transition-colors hover:border-[#2B6CB0]/35">
      <CardContent className="flex items-center gap-4 p-4">
        <Avatar className="size-12 border">
          <AvatarImage src={patient.avatarUrl} alt={patient.name} />
          <AvatarFallback className="bg-[#1B2D5B]/10 text-[#1B2D5B]">
            {patient.name.slice(0, 2).toUpperCase()}
          </AvatarFallback>
        </Avatar>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <p className="truncate font-semibold text-[#1B2D5B]">{patient.name}</p>
            <ClinicalBadge tone={patientTone(patient.status)}>{patient.status}</ClinicalBadge>
          </div>
          <p className="mt-1 text-sm text-muted-foreground">ID {patient.patientId}</p>
          <p className="mt-2 flex items-center gap-1.5 text-xs text-muted-foreground">
            <CalendarClock className="size-3.5" />
            Last visit {patient.lastVisit}
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
```

## Appointment Slot

Use for day schedules and doctor calendars. Scheduled uses YD blue, completed uses quiet success, and cancelled stays neutral so red remains reserved for alerts.

```tsx
import { Card, CardContent } from "@/components/ui/card";
import { CalendarCheck, Clock, Stethoscope } from "lucide-react";

type AppointmentStatus = "scheduled" | "completed" | "cancelled";

interface AppointmentSlotData {
  id: string;
  time: string;
  doctor: string;
  patient: string;
  status: AppointmentStatus;
}

function appointmentTone(status: AppointmentStatus) {
  if (status === "scheduled") return "normal";
  if (status === "completed") return "active";
  return "muted";
}

export function AppointmentSlotSkeleton() {
  return (
    <Card className="shadow-sm">
      <CardContent className="grid gap-3 p-4 sm:grid-cols-[96px_1fr_auto]">
        <FieldSkeleton className="h-6 w-20" />
        <div className="space-y-2">
          <FieldSkeleton className="h-5 w-40" />
          <FieldSkeleton className="w-52" />
        </div>
        <FieldSkeleton className="h-6 w-24 rounded-md" />
      </CardContent>
    </Card>
  );
}

export function AppointmentSlotEmpty() {
  return (
    <EmptyClinicState
      icon={CalendarCheck}
      title="No appointment slot"
      description="Choose a date or doctor to show available and scheduled appointment slots."
    />
  );
}

export function AppointmentSlot({
  appointment,
  isLoading,
}: {
  appointment?: AppointmentSlotData;
  isLoading?: boolean;
}) {
  if (isLoading) return <AppointmentSlotSkeleton />;
  if (!appointment) return <AppointmentSlotEmpty />;

  return (
    <Card className="shadow-sm">
      <CardContent className="grid items-center gap-3 p-4 sm:grid-cols-[96px_1fr_auto]">
        <div className="flex items-center gap-2 font-semibold text-[#1B2D5B]">
          <Clock className="size-4 text-[#2B6CB0]" />
          {appointment.time}
        </div>
        <div className="min-w-0">
          <p className="truncate font-medium text-foreground">{appointment.patient}</p>
          <p className="mt-1 flex items-center gap-1.5 text-sm text-muted-foreground">
            <Stethoscope className="size-3.5" />
            {appointment.doctor}
          </p>
        </div>
        <ClinicalBadge tone={appointmentTone(appointment.status)}>{appointment.status}</ClinicalBadge>
      </CardContent>
    </Card>
  );
}
```

## Vital Signs Display

Color code each reading by clinical range. Normal is blue, watch is amber, and alert is YD red. Do not use red for missing data.

```tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Activity, HeartPulse, Thermometer, Wind } from "lucide-react";

interface VitalSigns {
  heartRate: number;
  systolic: number;
  diastolic: number;
  temperatureC: number;
  spo2: number;
}

function vitalTone(metric: keyof VitalSigns | "bloodPressure", value: number, secondValue?: number): Tone {
  if (metric === "heartRate") {
    if (value < 40 || value > 130) return "alert";
    if (value < 60 || value > 100) return "watch";
    return "normal";
  }
  if (metric === "bloodPressure") {
    const systolic = value;
    const diastolic = secondValue ?? 0;
    if (systolic >= 180 || diastolic >= 120 || systolic <= 80 || diastolic <= 50) return "alert";
    if (systolic >= 140 || diastolic >= 90 || systolic < 90 || diastolic < 60) return "watch";
    return "normal";
  }
  if (metric === "temperatureC") {
    if (value >= 39.5 || value <= 35) return "alert";
    if (value >= 37.8 || value <= 35.9) return "watch";
    return "normal";
  }
  if (metric === "spo2") {
    if (value < 90) return "alert";
    if (value < 95) return "watch";
    return "normal";
  }
  return "normal";
}

function VitalTile({
  label,
  value,
  unit,
  tone,
  icon: Icon,
}: {
  label: string;
  value: string;
  unit: string;
  tone: Tone;
  icon: React.ComponentType<{ className?: string }>;
}) {
  return (
    <div className={cn("rounded-lg border p-3", toneClass(tone))}>
      <div className="flex items-center justify-between gap-3">
        <p className="text-xs font-medium uppercase tracking-normal">{label}</p>
        <Icon className="size-4 opacity-75" />
      </div>
      <p className="mt-3 text-2xl font-semibold tracking-tight">
        {value}
        <span className="ml-1 text-sm font-medium">{unit}</span>
      </p>
    </div>
  );
}

export function VitalSignsSkeleton() {
  return (
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
      {Array.from({ length: 4 }).map((_, index) => (
        <Skeleton key={index} className="h-28 rounded-lg" />
      ))}
    </div>
  );
}

export function VitalSignsEmpty() {
  return (
    <EmptyClinicState
      icon={HeartPulse}
      title="No vital signs recorded"
      description="Record heart rate, blood pressure, temperature, and SpO2 to populate this panel."
    />
  );
}

export function VitalSignsDisplay({ signs, isLoading }: { signs?: VitalSigns; isLoading?: boolean }) {
  if (isLoading) return <VitalSignsSkeleton />;
  if (!signs) return <VitalSignsEmpty />;

  return (
    <Card className="shadow-sm">
      <CardHeader>
        <CardTitle className="text-lg text-[#1B2D5B]">Vital signs</CardTitle>
      </CardHeader>
      <CardContent className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <VitalTile
          label="Heart rate"
          value={String(signs.heartRate)}
          unit="bpm"
          tone={vitalTone("heartRate", signs.heartRate)}
          icon={HeartPulse}
        />
        <VitalTile
          label="Blood pressure"
          value={`${signs.systolic}/${signs.diastolic}`}
          unit="mmHg"
          tone={vitalTone("bloodPressure", signs.systolic, signs.diastolic)}
          icon={Activity}
        />
        <VitalTile
          label="Temperature"
          value={signs.temperatureC.toFixed(1)}
          unit="deg C"
          tone={vitalTone("temperatureC", signs.temperatureC)}
          icon={Thermometer}
        />
        <VitalTile
          label="SpO2"
          value={String(signs.spo2)}
          unit="%"
          tone={vitalTone("spo2", signs.spo2)}
          icon={Wind}
        />
      </CardContent>
    </Card>
  );
}
```

## Medical Record Timeline

Use chronological events with compact icon markers. Alert events may use red; normal visits, labs, medications, and procedures use navy or blue.

```tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { AlertTriangle, ClipboardList, FlaskConical, Pill, Stethoscope } from "lucide-react";

type TimelineEventType = "visit" | "lab" | "medication" | "procedure" | "alert";

interface MedicalTimelineEvent {
  id: string;
  type: TimelineEventType;
  occurredAt: string;
  title: string;
  byline: string;
  note?: string;
}

const eventIcon = {
  visit: Stethoscope,
  lab: FlaskConical,
  medication: Pill,
  procedure: ClipboardList,
  alert: AlertTriangle,
} satisfies Record<TimelineEventType, React.ComponentType<{ className?: string }>>;

function eventTone(type: TimelineEventType) {
  return type === "alert" ? "alert" : "normal";
}

export function MedicalRecordTimelineSkeleton() {
  return (
    <div className="space-y-4">
      {Array.from({ length: 4 }).map((_, index) => (
        <div key={index} className="flex gap-3">
          <Skeleton className="size-9 rounded-full" />
          <div className="flex-1 space-y-2">
            <FieldSkeleton className="h-5 w-48" />
            <FieldSkeleton className="w-64" />
          </div>
        </div>
      ))}
    </div>
  );
}

export function MedicalRecordTimelineEmpty() {
  return (
    <EmptyClinicState
      icon={ClipboardList}
      title="No medical record events"
      description="Visits, lab results, medication changes, and procedures will appear here chronologically."
    />
  );
}

export function MedicalRecordTimeline({
  events,
  isLoading,
}: {
  events: MedicalTimelineEvent[];
  isLoading?: boolean;
}) {
  if (isLoading) return <MedicalRecordTimelineSkeleton />;
  if (events.length === 0) return <MedicalRecordTimelineEmpty />;

  return (
    <Card className="shadow-sm">
      <CardHeader>
        <CardTitle className="text-lg text-[#1B2D5B]">Medical record timeline</CardTitle>
      </CardHeader>
      <CardContent>
        <ol className="relative space-y-5 border-l pl-5">
          {events.map((event) => {
            const Icon = eventIcon[event.type];
            return (
              <li key={event.id} className="relative">
                <span
                  className={cn(
                    "absolute -left-[38px] flex size-8 items-center justify-center rounded-full border bg-background",
                    toneClass(eventTone(event.type)),
                  )}
                >
                  <Icon className="size-4" />
                </span>
                <div className="rounded-lg border bg-card p-3">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <p className="font-medium text-[#1B2D5B]">{event.title}</p>
                    <time className="text-xs text-muted-foreground">{event.occurredAt}</time>
                  </div>
                  <p className="mt-1 text-sm text-muted-foreground">{event.byline}</p>
                  {event.note ? <p className="mt-2 text-sm">{event.note}</p> : null}
                </div>
              </li>
            );
          })}
        </ol>
      </CardContent>
    </Card>
  );
}
```

## Doctor Profile Card

Use for doctor directories and appointment assignment. Availability should be immediately visible without using alert red unless there is an urgent operational issue.

```tsx
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { CalendarPlus, Stethoscope } from "lucide-react";

type DoctorAvailability = "available" | "in-consult" | "off-duty";

interface DoctorProfile {
  id: string;
  name: string;
  specialty: string;
  photoUrl?: string;
  availability: DoctorAvailability;
  nextSlot?: string;
}

function doctorTone(availability: DoctorAvailability) {
  if (availability === "available") return "active";
  if (availability === "in-consult") return "watch";
  return "muted";
}

export function DoctorProfileCardSkeleton() {
  return (
    <Card className="shadow-sm">
      <CardContent className="space-y-4 p-4">
        <div className="flex items-center gap-4">
          <Skeleton className="size-14 rounded-full" />
          <div className="space-y-2">
            <FieldSkeleton className="h-5 w-36" />
            <FieldSkeleton className="w-28" />
          </div>
        </div>
        <FieldSkeleton className="h-9 w-full" />
      </CardContent>
    </Card>
  );
}

export function DoctorProfileCardEmpty() {
  return (
    <EmptyClinicState
      icon={Stethoscope}
      title="No doctor profile"
      description="Select a doctor or specialty to view availability and appointment actions."
    />
  );
}

export function DoctorProfileCard({ doctor, isLoading }: { doctor?: DoctorProfile; isLoading?: boolean }) {
  if (isLoading) return <DoctorProfileCardSkeleton />;
  if (!doctor) return <DoctorProfileCardEmpty />;

  return (
    <Card className="shadow-sm">
      <CardContent className="space-y-4 p-4">
        <div className="flex items-center gap-4">
          <Avatar className="size-14 border">
            <AvatarImage src={doctor.photoUrl} alt={doctor.name} />
            <AvatarFallback className="bg-[#1B2D5B]/10 text-[#1B2D5B]">
              {doctor.name.slice(0, 2).toUpperCase()}
            </AvatarFallback>
          </Avatar>
          <div className="min-w-0 flex-1">
            <p className="truncate font-semibold text-[#1B2D5B]">{doctor.name}</p>
            <p className="mt-1 text-sm text-muted-foreground">{doctor.specialty}</p>
          </div>
          <ClinicalBadge tone={doctorTone(doctor.availability)}>{doctor.availability}</ClinicalBadge>
        </div>
        <div className="flex items-center justify-between gap-3 rounded-md bg-muted/40 px-3 py-2 text-sm">
          <span className="text-muted-foreground">Next slot</span>
          <span className="font-medium text-[#1B2D5B]">{doctor.nextSlot ?? "Not available"}</span>
        </div>
        <Button className="w-full bg-[#2B6CB0] hover:bg-[#1B2D5B]">
          <CalendarPlus className="mr-2 size-4" />
          Book appointment
        </Button>
      </CardContent>
    </Card>
  );
}
```

## Treatment Plan Table

Use a table when care plans have dates, procedures, statuses, and notes. Keep long notes muted and wrap them rather than squeezing all clinical context into badges.

```tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { ClipboardList } from "lucide-react";

type TreatmentStatus = "planned" | "in-progress" | "completed" | "blocked" | "cancelled";

interface TreatmentPlanItem {
  id: string;
  date: string;
  procedure: string;
  status: TreatmentStatus;
  notes?: string;
}

function treatmentTone(status: TreatmentStatus) {
  if (status === "blocked") return "alert";
  if (status === "in-progress") return "normal";
  if (status === "completed") return "active";
  if (status === "cancelled") return "muted";
  return "watch";
}

export function TreatmentPlanTableSkeleton() {
  return (
    <Table>
      <TableBody>
        {Array.from({ length: 5 }).map((_, index) => (
          <TableRow key={index}>
            <TableCell><FieldSkeleton className="w-24" /></TableCell>
            <TableCell><FieldSkeleton className="w-48" /></TableCell>
            <TableCell><FieldSkeleton className="h-6 w-24 rounded-md" /></TableCell>
            <TableCell><FieldSkeleton className="w-64" /></TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}

export function TreatmentPlanTableEmpty() {
  return (
    <EmptyClinicState
      icon={ClipboardList}
      title="No treatment plan"
      description="Create a treatment plan to track procedures, progress, and clinical notes."
    />
  );
}

export function TreatmentPlanTable({
  items,
  isLoading,
}: {
  items: TreatmentPlanItem[];
  isLoading?: boolean;
}) {
  if (isLoading) return <TreatmentPlanTableSkeleton />;
  if (items.length === 0) return <TreatmentPlanTableEmpty />;

  return (
    <Card className="shadow-sm">
      <CardHeader>
        <CardTitle className="text-lg text-[#1B2D5B]">Treatment plan</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="overflow-hidden rounded-lg border">
          <Table>
            <TableHeader>
              <TableRow className="bg-muted/50 hover:bg-muted/50">
                <TableHead>Date</TableHead>
                <TableHead>Procedure</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Notes</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {items.map((item) => (
                <TableRow key={item.id}>
                  <TableCell className="whitespace-nowrap font-medium text-[#1B2D5B]">{item.date}</TableCell>
                  <TableCell>{item.procedure}</TableCell>
                  <TableCell>
                    <ClinicalBadge tone={treatmentTone(item.status)}>{item.status}</ClinicalBadge>
                  </TableCell>
                  <TableCell className="max-w-md text-sm text-muted-foreground">
                    {item.notes ?? "No notes"}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  );
}
```

## Lab Results Card

Display the test name, measured value, reference range, and interpretation. Critical results use YD red and should be visually scannable from a list.

```tsx
import { Card, CardContent } from "@/components/ui/card";
import { AlertTriangle, FlaskConical } from "lucide-react";

type LabResultStatus = "normal" | "abnormal" | "critical";

interface LabResult {
  id: string;
  testName: string;
  value: string;
  referenceRange: string;
  status: LabResultStatus;
  collectedAt: string;
}

function labTone(status: LabResultStatus) {
  if (status === "critical") return "alert";
  if (status === "abnormal") return "watch";
  return "normal";
}

export function LabResultsCardSkeleton() {
  return (
    <Card className="shadow-sm">
      <CardContent className="space-y-4 p-4">
        <div className="flex items-center justify-between">
          <FieldSkeleton className="h-5 w-40" />
          <FieldSkeleton className="h-6 w-20 rounded-md" />
        </div>
        <FieldSkeleton className="h-8 w-28" />
        <FieldSkeleton className="w-48" />
      </CardContent>
    </Card>
  );
}

export function LabResultsCardEmpty() {
  return (
    <EmptyClinicState
      icon={FlaskConical}
      title="No lab results"
      description="Lab values and reference ranges will appear after results are received."
    />
  );
}

export function LabResultsCard({ result, isLoading }: { result?: LabResult; isLoading?: boolean }) {
  if (isLoading) return <LabResultsCardSkeleton />;
  if (!result) return <LabResultsCardEmpty />;

  const tone = labTone(result.status);

  return (
    <Card className={cn("shadow-sm", result.status === "critical" && "border-[#D42F2F]/40")}>
      <CardContent className="space-y-4 p-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            {result.status === "critical" ? (
              <AlertTriangle className="size-4 text-[#D42F2F]" />
            ) : (
              <FlaskConical className="size-4 text-[#2B6CB0]" />
            )}
            <p className="font-semibold text-[#1B2D5B]">{result.testName}</p>
          </div>
          <ClinicalBadge tone={tone}>{result.status}</ClinicalBadge>
        </div>
        <div>
          <p className={cn("text-3xl font-semibold tracking-tight", tone === "alert" ? "text-[#D42F2F]" : "text-[#1B2D5B]")}>
            {result.value}
          </p>
          <p className="mt-1 text-sm text-muted-foreground">Reference range {result.referenceRange}</p>
        </div>
        <p className="text-xs text-muted-foreground">Collected {result.collectedAt}</p>
      </CardContent>
    </Card>
  );
}
```

## Medication List

Use a compact list for current and historical medications. Dosage and frequency must be visible without opening a detail modal.

```tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Pill } from "lucide-react";

type MedicationStatus = "active" | "paused" | "stopped";

interface MedicationItem {
  id: string;
  drugName: string;
  dosage: string;
  frequency: string;
  startDate: string;
  endDate?: string;
  status: MedicationStatus;
}

function medicationTone(status: MedicationStatus) {
  if (status === "active") return "normal";
  if (status === "paused") return "watch";
  return "muted";
}

export function MedicationListSkeleton() {
  return (
    <div className="space-y-3">
      {Array.from({ length: 4 }).map((_, index) => (
        <div key={index} className="rounded-lg border p-3">
          <div className="flex items-center justify-between gap-3">
            <FieldSkeleton className="h-5 w-40" />
            <FieldSkeleton className="h-6 w-16 rounded-md" />
          </div>
          <FieldSkeleton className="mt-3 w-56" />
        </div>
      ))}
    </div>
  );
}

export function MedicationListEmpty() {
  return (
    <EmptyClinicState
      icon={Pill}
      title="No medications"
      description="Current prescriptions and medication history will appear here."
    />
  );
}

export function MedicationList({ medications, isLoading }: { medications: MedicationItem[]; isLoading?: boolean }) {
  if (isLoading) return <MedicationListSkeleton />;
  if (medications.length === 0) return <MedicationListEmpty />;

  return (
    <Card className="shadow-sm">
      <CardHeader>
        <CardTitle className="text-lg text-[#1B2D5B]">Medications</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {medications.map((medication, index) => (
          <div key={medication.id}>
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div className="min-w-0">
                <p className="font-semibold text-[#1B2D5B]">{medication.drugName}</p>
                <p className="mt-1 text-sm text-muted-foreground">
                  {medication.dosage} - {medication.frequency}
                </p>
                <p className="mt-1 text-xs text-muted-foreground">
                  {medication.startDate} to {medication.endDate ?? "current"}
                </p>
              </div>
              <ClinicalBadge tone={medicationTone(medication.status)}>{medication.status}</ClinicalBadge>
            </div>
            {index < medications.length - 1 ? <Separator className="mt-3" /> : null}
          </div>
        ))}
      </CardContent>
    </Card>
  );
}
```

## Clinic Dashboard KPI Cards

Use four cards for the clinic operator's daily scan: patients today, appointments, revenue, and wait time. Only use red when a KPI needs action, such as excessive wait time.

```tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Banknote, CalendarDays, Clock3, UsersRound } from "lucide-react";

type KpiTone = "normal" | "active" | "watch" | "alert";

interface ClinicKpi {
  key: "patients" | "appointments" | "revenue" | "waitTime";
  title: string;
  value: string;
  context: string;
  tone: KpiTone;
}

const kpiIcon = {
  patients: UsersRound,
  appointments: CalendarDays,
  revenue: Banknote,
  waitTime: Clock3,
} satisfies Record<ClinicKpi["key"], React.ComponentType<{ className?: string }>>;

function ClinicKpiCard({ kpi }: { kpi: ClinicKpi }) {
  const Icon = kpiIcon[kpi.key];

  return (
    <Card className={cn("shadow-sm", kpi.tone === "alert" && "border-[#D42F2F]/40")}>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{kpi.title}</CardTitle>
        <Icon className={cn("size-4", kpi.tone === "alert" ? "text-[#D42F2F]" : "text-[#2B6CB0]")} />
      </CardHeader>
      <CardContent>
        <div className={cn("text-2xl font-semibold tracking-tight", kpi.tone === "alert" ? "text-[#D42F2F]" : "text-[#1B2D5B]")}>
          {kpi.value}
        </div>
        <p className="mt-1 text-xs text-muted-foreground">{kpi.context}</p>
      </CardContent>
    </Card>
  );
}

export function ClinicDashboardKpiSkeleton() {
  return (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      {Array.from({ length: 4 }).map((_, index) => (
        <Skeleton key={index} className="h-32 rounded-lg" />
      ))}
    </div>
  );
}

export function ClinicDashboardKpiEmpty() {
  return (
    <EmptyClinicState
      icon={UsersRound}
      title="No KPI data"
      description="Daily patient count, appointments, revenue, and wait time will load after clinic data syncs."
    />
  );
}

export function ClinicDashboardKpis({ kpis, isLoading }: { kpis: ClinicKpi[]; isLoading?: boolean }) {
  if (isLoading) return <ClinicDashboardKpiSkeleton />;
  if (kpis.length === 0) return <ClinicDashboardKpiEmpty />;

  return (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      {kpis.map((kpi) => (
        <ClinicKpiCard key={kpi.key} kpi={kpi} />
      ))}
    </div>
  );
}
```

## Patient Registration Form

Use a multi-step form so front desk staff can validate identity before clinical intake. Validate each step before moving forward and keep the submit action blue.

```tsx
"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Progress } from "@/components/ui/progress";
import { UserPlus } from "lucide-react";
import { useMemo, useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";

const registrationSchema = z.object({
  firstName: z.string().min(1, "First name is required"),
  lastName: z.string().min(1, "Last name is required"),
  nationalId: z.string().min(6, "Enter a valid patient identifier"),
  dateOfBirth: z.string().min(1, "Date of birth is required"),
  phone: z.string().min(8, "Phone number is required"),
  address: z.string().min(1, "Address is required"),
  allergyStatus: z.enum(["none", "unknown", "has-allergies"]),
  allergies: z.string().optional(),
  emergencyContact: z.string().min(1, "Emergency contact is required"),
});

type RegistrationValues = z.infer<typeof registrationSchema>;

type RegistrationStep = {
  id: "identity" | "contact" | "clinical";
  label: string;
  fields: (keyof RegistrationValues)[];
};

const defaultRegistrationSteps: RegistrationStep[] = [
  { id: "identity", label: "Identity", fields: ["firstName", "lastName", "nationalId", "dateOfBirth"] },
  { id: "contact", label: "Contact", fields: ["phone", "address", "emergencyContact"] },
  { id: "clinical", label: "Clinical", fields: ["allergyStatus", "allergies"] },
];

export function PatientRegistrationSkeleton() {
  return (
    <Card className="shadow-sm">
      <CardHeader>
        <FieldSkeleton className="h-6 w-56" />
        <FieldSkeleton className="h-2 w-full" />
      </CardHeader>
      <CardContent className="grid gap-4 sm:grid-cols-2">
        {Array.from({ length: 6 }).map((_, index) => (
          <div key={index} className="space-y-2">
            <FieldSkeleton className="w-24" />
            <FieldSkeleton className="h-10 w-full" />
          </div>
        ))}
      </CardContent>
    </Card>
  );
}

export function PatientRegistrationEmpty() {
  return (
    <EmptyClinicState
      icon={UserPlus}
      title="Registration unavailable"
      description="Registration steps are not configured. Check the clinic intake configuration."
    />
  );
}

export function PatientRegistrationForm({
  isLoading,
  onSubmit,
  steps = defaultRegistrationSteps,
}: {
  isLoading?: boolean;
  onSubmit: (values: RegistrationValues) => Promise<void> | void;
  steps?: RegistrationStep[];
}) {
  const [stepIndex, setStepIndex] = useState(0);
  const step = steps[stepIndex];

  const form = useForm<RegistrationValues>({
    resolver: zodResolver(registrationSchema),
    defaultValues: {
      firstName: "",
      lastName: "",
      nationalId: "",
      dateOfBirth: "",
      phone: "",
      address: "",
      allergyStatus: "unknown",
      allergies: "",
      emergencyContact: "",
    },
  });

  const progress = useMemo(() => {
    if (steps.length === 0) return 0;
    return ((Math.min(stepIndex, steps.length - 1) + 1) / steps.length) * 100;
  }, [stepIndex, steps.length]);

  if (isLoading) return <PatientRegistrationSkeleton />;
  if (!step) return <PatientRegistrationEmpty />;

  async function goNext() {
    const valid = await form.trigger(step.fields, { shouldFocus: true });
    if (valid) setStepIndex((current) => Math.min(current + 1, steps.length - 1));
  }

  return (
    <Card className="shadow-sm">
      <CardHeader className="space-y-4">
        <div>
          <CardTitle className="text-lg text-[#1B2D5B]">Patient registration</CardTitle>
          <p className="mt-1 text-sm text-muted-foreground">{step.label} information</p>
        </div>
        <Progress value={progress} className="h-2" />
        <div className="grid gap-2 sm:grid-cols-3">
          {steps.map((item, index) => (
            <div
              key={item.id}
              className={cn(
                "rounded-md border px-3 py-2 text-sm font-medium",
                index === stepIndex ? "border-[#2B6CB0] bg-[#2B6CB0]/10 text-[#1B2D5B]" : "text-muted-foreground",
              )}
            >
              {item.label}
            </div>
          ))}
        </div>
      </CardHeader>
      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)}>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            {step.id === "identity" ? (
              <>
                <FormField
                  control={form.control}
                  name="firstName"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>First name</FormLabel>
                      <FormControl><Input {...field} autoComplete="given-name" /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="lastName"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Last name</FormLabel>
                      <FormControl><Input {...field} autoComplete="family-name" /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="nationalId"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Patient ID</FormLabel>
                      <FormControl><Input {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="dateOfBirth"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Date of birth</FormLabel>
                      <FormControl><Input {...field} type="date" /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </>
            ) : null}

            {step.id === "contact" ? (
              <>
                <FormField
                  control={form.control}
                  name="phone"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Phone</FormLabel>
                      <FormControl><Input {...field} autoComplete="tel" /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="emergencyContact"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Emergency contact</FormLabel>
                      <FormControl><Input {...field} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="address"
                  render={({ field }) => (
                    <FormItem className="sm:col-span-2">
                      <FormLabel>Address</FormLabel>
                      <FormControl><Textarea {...field} rows={3} /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </>
            ) : null}

            {step.id === "clinical" ? (
              <>
                <FormField
                  control={form.control}
                  name="allergyStatus"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Allergy status</FormLabel>
                      <Select onValueChange={field.onChange} defaultValue={field.value}>
                        <FormControl>
                          <SelectTrigger><SelectValue placeholder="Select allergy status" /></SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="none">No known allergies</SelectItem>
                          <SelectItem value="unknown">Unknown</SelectItem>
                          <SelectItem value="has-allergies">Has allergies</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="allergies"
                  render={({ field }) => (
                    <FormItem className="sm:col-span-2">
                      <FormLabel>Allergy notes</FormLabel>
                      <FormControl><Textarea {...field} rows={3} placeholder="Medication, food, or material allergies" /></FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </>
            ) : null}
          </CardContent>
          <CardFooter className="flex justify-between gap-3">
            <Button
              type="button"
              variant="outline"
              disabled={stepIndex === 0}
              onClick={() => setStepIndex((current) => Math.max(current - 1, 0))}
            >
              Back
            </Button>
            {stepIndex < steps.length - 1 ? (
              <Button type="button" className="bg-[#2B6CB0] hover:bg-[#1B2D5B]" onClick={goNext}>
                Continue
              </Button>
            ) : (
              <Button type="submit" className="bg-[#2B6CB0] hover:bg-[#1B2D5B]" disabled={form.formState.isSubmitting}>
                {form.formState.isSubmitting ? "Registering..." : "Register patient"}
              </Button>
            )}
          </CardFooter>
        </form>
      </Form>
    </Card>
  );
}
```
