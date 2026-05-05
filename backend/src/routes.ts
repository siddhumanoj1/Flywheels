import bcrypt from 'bcryptjs';
import { ApprovalStatus, DocumentType, JobStatus, Prisma, Role } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { env } from './config/env';
import { AppError } from './lib/errors';
import { documentNumberPrefix, documentKindSchema, type ParsedLineItem } from './lib/document-types';
import { signAccessToken } from './lib/jwt';
import { prisma } from './lib/prisma';
import { requireAuth, requireRole, type AuthenticatedRequest } from './middlewares/auth';
import { applyDocumentMutation } from './services/document-mutation.service';
import { parseOwnerDocumentInput } from './services/document-parser.service';
import { buildDocumentPdf } from './services/document-pdf.service';
import { buildServiceSuggestions } from './services/recommendation.service';

const router = Router();

const phoneSchema = z.object({
  phone: z.string().min(10).max(15),
});

const verifyOtpSchema = phoneSchema.extend({
  code: z.string().length(6),
});

const carSchema = z.object({
  carNumber: z.string().min(1),
  model: z.string().min(1),
  fuelType: z.string().min(1),
  year: z.coerce.number().int().min(1980).max(2100),
  userId: z.string().optional(),
});

const documentSaveSchema = z.object({
  jobId: z.string().optional(),
  carId: z.string().optional(),
  customerId: z.string().optional(),
  rawText: z.string().optional(),
  parsed: z
    .object({
      type: documentKindSchema,
      vehicleNumber: z.string(),
      carModel: z.string(),
      customerName: z.string(),
      items: z.array(
        z.object({
          description: z.string(),
          quantity: z.number(),
          unitPrice: z.number(),
          total: z.number(),
        })
      ),
      subtotal: z.number(),
      total: z.number(),
      sourceText: z.string(),
    })
    .optional(),
});

const decisionSchema = z.object({
  decision: z.enum(['approved', 'rejected']),
  comments: z.string().optional(),
});

function generateOtpCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function generateDocumentNumber(type: 'invoice' | 'quotation' | 'estimation') {
  const stamp = `${Date.now()}`.slice(-6);
  return `${documentNumberPrefix(type)}-${stamp}`;
}

function serializeItems(items: Prisma.JsonValue): ParsedLineItem[] {
  return Array.isArray(items) ? (items as unknown as ParsedLineItem[]) : [];
}

router.get('/health', (_req, res) => {
  res.json({
    success: true,
    message: 'FLYWHEELS AUTO backend healthy',
    uptime: process.uptime(),
  });
});

router.post('/api/v1/auth/request-otp', async (req, res, next) => {
  try {
    const { phone } = phoneSchema.parse(req.body);
    const code = generateOtpCode();
    const codeHash = await bcrypt.hash(code, 10);
    const expiresAt = new Date(Date.now() + env.OTP_TTL_MINUTES * 60 * 1000);

    const existingUser = await prisma.user.findUnique({ where: { phone } });

    await prisma.otpCode.create({
      data: {
        phone,
        codeHash,
        expiresAt,
        userId: existingUser?.id,
      },
    });

    if (!existingUser) {
      await prisma.user.create({
        data: {
          role: Role.CUSTOMER,
          phone,
          name: `Customer ${phone.slice(-4)}`,
        },
      });
    }

    res.json({
      success: true,
      message: 'OTP generated.',
      devOtp: env.NODE_ENV === 'production' ? undefined : code,
    });
  } catch (error) {
    next(error);
  }
});

router.post('/api/v1/auth/verify-otp', async (req, res, next) => {
  try {
    const { phone, code } = verifyOtpSchema.parse(req.body);
    const otp = await prisma.otpCode.findFirst({
      where: {
        phone,
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otp) {
      throw new AppError(400, 'OTP expired or not found.');
    }

    const isMatch = await bcrypt.compare(code, otp.codeHash);
    if (!isMatch) {
      throw new AppError(400, 'Invalid OTP.');
    }

    await prisma.otpCode.update({
      where: { id: otp.id },
      data: { usedAt: new Date() },
    });

    const user = await prisma.user.findUnique({ where: { phone } });
    if (!user) {
      throw new AppError(404, 'User account not found after OTP verification.');
    }

    const token = signAccessToken({
      sub: user.id,
      phone: user.phone,
      role: user.role === Role.OWNER ? 'owner' : 'customer',
    });

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        role: user.role === Role.OWNER ? 'owner' : 'customer',
        name: user.name,
        phone: user.phone,
      },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/api/v1/me', requireAuth, async (req: AuthenticatedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.auth!.userId },
      include: { loyaltyEntries: true },
    });

    if (!user) {
      throw new AppError(404, 'User not found.');
    }

    res.json({
      success: true,
      data: {
        id: user.id,
        name: user.name,
        role: user.role === Role.OWNER ? 'owner' : 'customer',
        phone: user.phone,
        email: user.email,
        address: user.address,
        gst: user.gst,
        loyaltyPoints: user.loyaltyEntries.reduce((sum, entry) => sum + entry.points, 0),
      },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/api/v1/cars', requireAuth, async (req: AuthenticatedRequest, res, next) => {
  try {
    const cars = await prisma.car.findMany({
      where: req.auth!.role === 'customer' ? { userId: req.auth!.userId } : undefined,
      include: {
        jobs: {
          orderBy: { updatedAt: 'desc' },
          take: 1,
        },
        user: true,
      },
      orderBy: { updatedAt: 'desc' },
    });
    res.json({ success: true, data: cars });
  } catch (error) {
    next(error);
  }
});

router.post('/api/v1/cars', requireAuth, async (req: AuthenticatedRequest, res, next) => {
  try {
    const payload = carSchema.parse(req.body);
    const car = await prisma.car.create({
      data: {
        ...payload,
        userId: req.auth!.role === 'owner' && payload.userId ? payload.userId : req.auth!.userId,
      },
    });
    res.status(201).json({ success: true, data: car });
  } catch (error) {
    next(error);
  }
});

router.patch('/api/v1/cars/:id/active', requireAuth, async (req: AuthenticatedRequest, res, next) => {
  try {
    const id = z.string().parse(req.params.id);
    const target = await prisma.car.findUnique({ where: { id } });
    if (!target) {
      throw new AppError(404, 'Car not found.');
    }
    if (req.auth!.role === 'customer' && target.userId !== req.auth!.userId) {
      throw new AppError(403, 'You cannot change another customer car.');
    }

    await prisma.$transaction([
      prisma.car.updateMany({
        where: { userId: target.userId },
        data: { isActive: false },
      }),
      prisma.car.update({
        where: { id: target.id },
        data: { isActive: true },
      }),
    ]);

    res.json({ success: true, message: 'Active car updated.' });
  } catch (error) {
    next(error);
  }
});

router.get('/api/v1/jobs', requireAuth, async (req: AuthenticatedRequest, res, next) => {
  try {
    const jobs = await prisma.job.findMany({
      where:
        req.auth!.role === 'customer'
          ? {
              car: {
                userId: req.auth!.userId,
              },
            }
          : undefined,
      include: {
        car: true,
        documents: true,
        pickupRequests: true,
      },
      orderBy: { updatedAt: 'desc' },
    });
    res.json({ success: true, data: jobs });
  } catch (error) {
    next(error);
  }
});

router.patch('/api/v1/jobs/:id/status', requireAuth, requireRole('owner'), async (req, res, next) => {
  try {
    const id = z.string().parse(req.params.id);
    const body = z.object({ status: z.nativeEnum(JobStatus) }).parse(req.body);
    const job = await prisma.job.update({
      where: { id },
      data: { status: body.status },
      include: {
        car: true,
      },
    });

    await prisma.notification.create({
      data: {
        userId: job.car.userId,
        title: 'Car status updated',
        message: `${job.car.carNumber} is now ${body.status.replace(/_/g, ' ').toLowerCase()}.`,
      },
    });

    res.json({ success: true, data: job });
  } catch (error) {
    next(error);
  }
});

router.get('/api/v1/cars/:id/suggestions', requireAuth, async (req: AuthenticatedRequest, res, next) => {
  try {
    const id = z.string().parse(req.params.id);
    const car = await prisma.car.findUnique({
      where: { id },
      include: { documents: true },
    });
    if (!car) {
      throw new AppError(404, 'Car not found.');
    }
    if (req.auth!.role === 'customer' && car.userId !== req.auth!.userId) {
      throw new AppError(403, 'You cannot access suggestions for another customer car.');
    }

    const items = car.documents.flatMap((document) => serializeItems(document.items));
    res.json({
      success: true,
      data: buildServiceSuggestions(car.model, items),
    });
  } catch (error) {
    next(error);
  }
});

router.post('/api/v1/documents/parse', requireAuth, requireRole('owner'), async (req, res, next) => {
  try {
    const body = z.object({ rawText: z.string().min(1) }).parse(req.body);
    const parsed = parseOwnerDocumentInput(body.rawText);
    res.json({ success: true, data: parsed });
  } catch (error) {
    next(error);
  }
});

router.post('/api/v1/documents', requireAuth, requireRole('owner'), async (req, res, next) => {
  try {
    const body = documentSaveSchema.parse(req.body);
    const parsed = body.parsed ?? parseOwnerDocumentInput(body.rawText ?? '');

    let customerId = body.customerId;
    let carId = body.carId;

    if (!customerId || !carId) {
      const car = await prisma.car.findFirst({
        where: {
          carNumber: parsed.vehicleNumber,
        },
      });
      if (car) {
        carId = car.id;
        customerId = car.userId;
      }
    }

    if (!customerId) {
      const createdCustomer = await prisma.user.create({
        data: {
          role: Role.CUSTOMER,
          name: parsed.customerName,
          phone: `pending-${Date.now()}`,
        },
      });
      customerId = createdCustomer.id;
    }

    const document = await prisma.document.create({
      data: {
        documentNumber: generateDocumentNumber(parsed.type),
        type: DocumentType[parsed.type.toUpperCase() as keyof typeof DocumentType],
        customerId,
        carId,
        jobId: body.jobId,
        items: parsed.items as unknown as Prisma.InputJsonValue,
        subtotal: new Prisma.Decimal(parsed.subtotal.toFixed(2)),
        total: new Prisma.Decimal(parsed.total.toFixed(2)),
        approvalStatus:
          parsed.type === 'invoice' ? ApprovalStatus.APPROVED : ApprovalStatus.PENDING,
      },
    });

    res.status(201).json({ success: true, data: document });
  } catch (error) {
    next(error);
  }
});

router.get('/api/v1/documents', requireAuth, async (req: AuthenticatedRequest, res, next) => {
  try {
    const documents = await prisma.document.findMany({
      where: req.auth!.role === 'customer' ? { customerId: req.auth!.userId } : undefined,
      include: {
        car: true,
        job: true,
        customer: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: documents });
  } catch (error) {
    next(error);
  }
});

router.post('/api/v1/documents/:id/decision', requireAuth, requireRole('customer'), async (req: AuthenticatedRequest, res, next) => {
  try {
    const id = z.string().parse(req.params.id);
    const body = decisionSchema.parse(req.body);
    const document = await prisma.document.findUnique({ where: { id } });
    if (!document) {
      throw new AppError(404, 'Document not found.');
    }
    if (document.customerId !== req.auth!.userId) {
      throw new AppError(403, 'You cannot approve another customer document.');
    }

    const updated = await prisma.document.update({
      where: { id: document.id },
      data: {
        approvalStatus: body.decision === 'approved' ? ApprovalStatus.APPROVED : ApprovalStatus.REJECTED,
        comments: body.comments,
        approvedAt: body.decision === 'approved' ? new Date() : null,
      },
    });
    res.json({ success: true, data: updated });
  } catch (error) {
    next(error);
  }
});

router.post('/api/v1/documents/:id/mutate', requireAuth, requireRole('owner'), async (req, res, next) => {
  try {
    const id = z.string().parse(req.params.id);
    const body = z.object({ request: z.string().min(1) }).parse(req.body);
    const existing = await prisma.document.findUnique({
      where: { id },
      include: {
        car: true,
        customer: true,
      },
    });
    if (!existing) {
      throw new AppError(404, 'Document not found.');
    }

    const transformed = applyDocumentMutation(
      {
        type: existing.type.toLowerCase() as 'invoice' | 'quotation' | 'estimation',
        vehicleNumber: existing.car?.carNumber ?? '',
        carModel: existing.car?.model ?? '',
        customerName: existing.customer.name,
        items: serializeItems(existing.items),
        subtotal: Number(existing.subtotal),
        total: Number(existing.total),
        sourceText: '',
      },
      body.request
    );

    const updated = await prisma.document.update({
      where: { id: existing.id },
      data: {
        items: transformed.items as unknown as Prisma.InputJsonValue,
        subtotal: new Prisma.Decimal(transformed.subtotal.toFixed(2)),
        total: new Prisma.Decimal(transformed.total.toFixed(2)),
      },
    });

    res.json({ success: true, data: updated });
  } catch (error) {
    next(error);
  }
});

router.get('/api/v1/documents/:id/pdf', requireAuth, async (req: AuthenticatedRequest, res, next) => {
  try {
    const id = z.string().parse(req.params.id);
    const document = await prisma.document.findUnique({
      where: { id },
      include: { customer: true, car: true },
    });
    if (!document) {
      throw new AppError(404, 'Document not found.');
    }
    if (req.auth!.role === 'customer' && document.customerId !== req.auth!.userId) {
      throw new AppError(403, 'You cannot view another customer document.');
    }

    const pdf = await buildDocumentPdf({
      documentNumber: document.documentNumber,
      type: document.type.toLowerCase() as 'invoice' | 'quotation' | 'estimation',
      vehicleNumber: document.car?.carNumber ?? '',
      carModel: document.car?.model ?? '',
      customerName: document.customer.name,
      items: serializeItems(document.items),
      subtotal: Number(document.subtotal),
      total: Number(document.total),
      sourceText: '',
    });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `inline; filename="${document.documentNumber}.pdf"`);
    res.send(pdf);
  } catch (error) {
    next(error);
  }
});

router.get('/api/v1/owner/dashboard', requireAuth, requireRole('owner'), async (_req, res, next) => {
  try {
    const [jobsInGarage, pendingApprovals, completedJobs, revenueAggregate] = await Promise.all([
      prisma.job.count({
        where: {
          status: {
            in: [JobStatus.RECEIVED, JobStatus.UNDER_INSPECTION, JobStatus.WORK_IN_PROGRESS],
          },
        },
      }),
      prisma.document.count({
        where: {
          approvalStatus: ApprovalStatus.PENDING,
          type: { in: [DocumentType.QUOTATION, DocumentType.ESTIMATION] },
        },
      }),
      prisma.job.count({
        where: { status: JobStatus.COMPLETED },
      }),
      prisma.document.aggregate({
        _sum: { total: true },
        where: {
          type: DocumentType.INVOICE,
          createdAt: { gte: new Date(new Date().setHours(0, 0, 0, 0)) },
        },
      }),
    ]);

    res.json({
      success: true,
      data: {
        carsInGarage: jobsInGarage,
        pendingApprovals,
        completedJobs,
        revenueToday: Number(revenueAggregate._sum.total ?? 0),
      },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/api/v1/notifications', requireAuth, async (req: AuthenticatedRequest, res, next) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.auth!.userId },
      orderBy: { createdAt: 'desc' },
      take: 30,
    });
    res.json({ success: true, data: notifications });
  } catch (error) {
    next(error);
  }
});

router.post('/api/v1/telegram/webhook', async (req, res, next) => {
  try {
    const messageText = z.string().parse(req.body?.message?.text ?? '');
    const keyword = messageText.split(/\s+/)[0].toLowerCase();
    const mappedType =
      keyword === 'invoice'
        ? 'invoice'
        : keyword === 'quote' || keyword === 'quotation'
          ? 'quotation'
          : keyword === 'estimate' || keyword === 'estimation'
            ? 'estimation'
            : null;

    if (!mappedType) {
      return res.json({
        success: true,
        reply: 'Start your message with invoice, quote, quotation, estimate, or estimation.',
      });
    }

    const rawText = messageText.replace(/^(invoice|quote|quotation|estimate|estimation)\s*/i, `${mappedType}\n`);
    const parsed = parseOwnerDocumentInput(rawText);
    res.json({
      success: true,
      reply: `Your ${mappedType} has been parsed successfully.`,
      data: parsed,
      viewUrl: `${env.PUBLIC_BASE_URL}/api/v1/documents/preview`,
    });
  } catch (error) {
    next(error);
  }
});

export { router };
