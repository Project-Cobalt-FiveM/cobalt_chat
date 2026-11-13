import { toNuiMessage } from './types';
import type { NuiCallbacks, NuiMessage } from './types';

declare global {
  interface Window {
    GetParentResourceName?: () => string;
  }
}

export const inGame = typeof window.GetParentResourceName === 'function';

export async function fetchNui<K extends keyof NuiCallbacks>(name: K, data: NuiCallbacks[K]): Promise<void> {
  const resource = window.GetParentResourceName?.();
  if (!resource) return;

  try {
    await fetch(`https://${resource}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
  } catch {
    return;
  }
}

export function onNuiMessage(handler: (message: NuiMessage) => void): () => void {
  const listener = (event: MessageEvent<unknown>) => {
    const message = toNuiMessage(event.data);
    if (message) handler(message);
  };

  window.addEventListener('message', listener);
  return () => window.removeEventListener('message', listener);
}
