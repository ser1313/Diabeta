ALTER TABLE "GlucoseReading" ADD COLUMN "clientRequestId" UUID;

CREATE UNIQUE INDEX "GlucoseReading_userId_clientRequestId_key"
ON "GlucoseReading"("userId", "clientRequestId");
