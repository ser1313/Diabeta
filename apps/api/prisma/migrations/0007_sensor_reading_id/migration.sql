ALTER TABLE "GlucoseReading" ADD COLUMN "externalReadingId" VARCHAR(200);

CREATE UNIQUE INDEX "GlucoseReading_userId_source_externalReadingId_key"
ON "GlucoseReading"("userId", "source", "externalReadingId");
