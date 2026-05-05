import { ParsedDocument } from '../lib/document-types';
import { AppError } from '../lib/errors';

function recalculate(document: ParsedDocument): ParsedDocument {
  const subtotal = document.items.reduce((sum, item) => sum + item.total, 0);
  return {
    ...document,
    subtotal,
    total: subtotal,
  };
}

export function applyDocumentMutation(document: ParsedDocument, request: string): ParsedDocument {
  const normalized = request.trim().toLowerCase();

  if (normalized.startsWith('remove ')) {
    const needle = normalized.replace(/^remove\s+/, '');
    const items = document.items.filter((item) => !item.description.toLowerCase().includes(needle));
    return recalculate({ ...document, items });
  }

  const addMatch = request.match(/^add\s+(.+?)\s+for\s+(\d+(?:\.\d+)?)\s*(each)?$/i);
  if (addMatch) {
    const description = addMatch[1].trim();
    const price = Number(addMatch[2]);
    const quantityMatch = description.match(/^(\d+)\s+(.+)$/);
    const quantity = quantityMatch ? Number(quantityMatch[1]) : 1;
    const normalizedDescription = quantityMatch ? quantityMatch[2] : description;

    return recalculate({
      ...document,
      items: [
        ...document.items,
        {
          description: normalizedDescription,
          quantity,
          unitPrice: price,
          total: price * quantity,
        },
      ],
    });
  }

  const updateMatch = request.match(/^update\s+(.+?)\s+to\s+(\d+(?:\.\d+)?)$/i);
  if (updateMatch) {
    const needle = updateMatch[1].trim().toLowerCase();
    const nextPrice = Number(updateMatch[2]);
    let found = false;

    const items = document.items.map((item) => {
      if (!item.description.toLowerCase().includes(needle)) {
        return item;
      }
      found = true;
      return {
        ...item,
        unitPrice: nextPrice,
        total: nextPrice * item.quantity,
      };
    });

    if (!found) {
      throw new AppError(404, `No line item matched "${updateMatch[1]}".`);
    }

    return recalculate({ ...document, items });
  }

  throw new AppError(400, 'Unsupported modification request. Use add/remove/update phrasing.');
}

