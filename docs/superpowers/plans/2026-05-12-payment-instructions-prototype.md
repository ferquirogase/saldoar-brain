# Payment Instructions Prototype — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Crear un prototipo standalone de la pantalla de instrucciones de pago (variante fiat directo) con el modelo de checkpoints, corriendo en local para demo.

**Architecture:** Proyecto React + Vite standalone con datos mockeados. No hay backend real — el estado se maneja localmente con React state. La página replica el flujo completo del comprador (3 checkpoints progresivos + CTA flotante) y la vista del vendedor (solo lectura).

**Tech Stack:** React 18, Vite, Tailwind CSS 3, Vitest para tests de lógica.

**Proyecto:** Crear en `C:\Users\Marketing\Desktop\saldoar-instructions-demo` (proyecto nuevo, NO dentro del repo Saldoar brain).

---

## File Structure

```
saldoar-instructions-demo/
├── index.html
├── vite.config.js
├── tailwind.config.js
├── postcss.config.js
├── package.json
├── src/
│   ├── main.jsx
│   ├── App.jsx                          ← router entre vista comprador y vendedor
│   ├── data/
│   │   └── mockTransaction.js           ← datos mockeados de la transacción
│   ├── hooks/
│   │   └── useCheckpointState.js        ← máquina de estado de los checkpoints
│   ├── components/
│   │   ├── TransactionHeader.jsx        ← header fijo con monto + contraparte
│   │   ├── HelperBanner.jsx             ← banner contextual con severidad
│   │   ├── FloatingCTA.jsx              ← botón sticky que cambia por checkpoint
│   │   ├── checkpoints/
│   │   │   ├── Checkpoint.jsx           ← wrapper con estado visual (pending/active/done)
│   │   │   ├── CheckpointTransfer.jsx   ← checkpoint 1: datos bancarios
│   │   │   ├── CheckpointConfirm.jsx    ← checkpoint 2: avisar que pagaste
│   │   │   └── CheckpointProof.jsx      ← checkpoint 3: subir comprobante
│   │   └── seller/
│   │       └── SellerView.jsx           ← vista de solo lectura del vendedor
│   └── pages/
│       ├── BuyerPage.jsx                ← página principal del comprador
│       └── SellerPage.jsx               ← página principal del vendedor
└── src/hooks/
    └── __tests__/
        └── useCheckpointState.test.js
```

---

## Task 1: Scaffoldear el proyecto

**Files:**
- Create: `C:\Users\Marketing\Desktop\saldoar-instructions-demo\` (directorio nuevo)

- [ ] **Step 1: Crear el proyecto con Vite**

Desde PowerShell en `C:\Users\Marketing\Desktop`:

```powershell
npm create vite@latest saldoar-instructions-demo -- --template react
cd saldoar-instructions-demo
npm install
```

- [ ] **Step 2: Instalar Tailwind CSS**

```powershell
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

- [ ] **Step 3: Configurar Tailwind**

Reemplazar el contenido de `tailwind.config.js`:

```js
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50:  '#f0fdf4',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
        }
      }
    }
  },
  plugins: [],
}
```

- [ ] **Step 4: Agregar Tailwind al CSS global**

Reemplazar `src/index.css` completo:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

* { box-sizing: border-box; }
body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f9fafb; }
```

- [ ] **Step 5: Instalar Vitest**

```powershell
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom
```

- [ ] **Step 6: Configurar Vitest en vite.config.js**

Reemplazar `vite.config.js`:

```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: './src/test-setup.js',
  },
})
```

- [ ] **Step 7: Crear test-setup.js**

Crear `src/test-setup.js`:

```js
import '@testing-library/jest-dom'
```

- [ ] **Step 8: Verificar que el proyecto levanta**

```powershell
npm run dev
```

Esperado: servidor en `http://localhost:5173` sin errores.

- [ ] **Step 9: Commit inicial**

```powershell
git init
git add .
git commit -m "chore: scaffold React + Vite + Tailwind project"
```

---

## Task 2: Mock data y tipos

**Files:**
- Create: `src/data/mockTransaction.js`

- [ ] **Step 1: Crear mock data**

Crear `src/data/mockTransaction.js`:

```js
export const mockTransaction = {
  id: 'txn-001',
  mid: 'SLD-20240512-001',
  amount: 45000,
  currency: 'ARS',
  counterparty: {
    name: 'Juan García',
    role: 'vendedor',
  },
  directTransfers1: [
    {
      id: 'dt1-001',
      bank: 'Banco Galicia',
      cbu: '0070123400000123456789',
      alias: 'JUAN.GARCIA.MP',
      accountType: 'Caja de ahorro',
      holder: 'Juan García',
      behaviour: 'UNREAD',
    },
  ],
  helper: null,
  // helper example:
  // helper: {
  //   severity: 'warning',
  //   title: 'Validación requerida',
  //   message: 'Debés completar tu identidad antes de continuar.',
  //   dismissible: false,
  // }
}

export const CHECKPOINT = {
  TRANSFER: 'transfer',
  CONFIRM:  'confirm',
  PROOF:    'proof',
  DONE:     'done',
}

export const CHECKPOINT_ORDER = [
  CHECKPOINT.TRANSFER,
  CHECKPOINT.CONFIRM,
  CHECKPOINT.PROOF,
]
```

- [ ] **Step 2: Commit**

```powershell
git add src/data/mockTransaction.js
git commit -m "feat: add mock transaction data"
```

---

## Task 3: Hook de estado de checkpoints

**Files:**
- Create: `src/hooks/useCheckpointState.js`
- Create: `src/hooks/__tests__/useCheckpointState.test.js`

- [ ] **Step 1: Escribir el test primero**

Crear `src/hooks/__tests__/useCheckpointState.test.js`:

```js
import { describe, it, expect } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useCheckpointState } from '../useCheckpointState'
import { CHECKPOINT } from '../../data/mockTransaction'

describe('useCheckpointState', () => {
  it('starts on TRANSFER checkpoint', () => {
    const { result } = renderHook(() => useCheckpointState())
    expect(result.current.active).toBe(CHECKPOINT.TRANSFER)
  })

  it('advances to CONFIRM after completing TRANSFER', () => {
    const { result } = renderHook(() => useCheckpointState())
    act(() => result.current.advance())
    expect(result.current.active).toBe(CHECKPOINT.CONFIRM)
  })

  it('advances to PROOF after completing CONFIRM', () => {
    const { result } = renderHook(() => useCheckpointState())
    act(() => result.current.advance())
    act(() => result.current.advance())
    expect(result.current.active).toBe(CHECKPOINT.PROOF)
  })

  it('reaches DONE after completing PROOF', () => {
    const { result } = renderHook(() => useCheckpointState())
    act(() => result.current.advance())
    act(() => result.current.advance())
    act(() => result.current.advance())
    expect(result.current.active).toBe(CHECKPOINT.DONE)
  })

  it('isCompleted returns true for past checkpoints', () => {
    const { result } = renderHook(() => useCheckpointState())
    act(() => result.current.advance())
    expect(result.current.isCompleted(CHECKPOINT.TRANSFER)).toBe(true)
    expect(result.current.isCompleted(CHECKPOINT.CONFIRM)).toBe(false)
  })
})
```

- [ ] **Step 2: Correr el test para verificar que falla**

```powershell
npx vitest run src/hooks/__tests__/useCheckpointState.test.js
```

Esperado: FAIL — "Cannot find module"

- [ ] **Step 3: Implementar el hook**

Crear `src/hooks/useCheckpointState.js`:

```js
import { useState } from 'react'
import { CHECKPOINT, CHECKPOINT_ORDER } from '../data/mockTransaction'

export function useCheckpointState() {
  const [completedSet, setCompletedSet] = useState(new Set())
  const [activeIndex, setActiveIndex] = useState(0)

  const active = activeIndex < CHECKPOINT_ORDER.length
    ? CHECKPOINT_ORDER[activeIndex]
    : CHECKPOINT.DONE

  function advance() {
    const current = CHECKPOINT_ORDER[activeIndex]
    if (!current) return
    setCompletedSet(prev => new Set([...prev, current]))
    setActiveIndex(i => i + 1)
  }

  function isCompleted(checkpoint) {
    return completedSet.has(checkpoint)
  }

  return { active, advance, isCompleted }
}
```

- [ ] **Step 4: Correr el test para verificar que pasa**

```powershell
npx vitest run src/hooks/__tests__/useCheckpointState.test.js
```

Esperado: 5 tests PASS

- [ ] **Step 5: Commit**

```powershell
git add src/hooks/
git commit -m "feat: add checkpoint state machine hook"
```

---

## Task 4: TransactionHeader

**Files:**
- Create: `src/components/TransactionHeader.jsx`

- [ ] **Step 1: Crear el componente**

Crear `src/components/TransactionHeader.jsx`:

```jsx
export function TransactionHeader({ transaction }) {
  const formatted = new Intl.NumberFormat('es-AR', {
    style: 'currency',
    currency: transaction.currency,
    maximumFractionDigits: 0,
  }).format(transaction.amount)

  return (
    <header className="sticky top-0 z-10 bg-white border-b border-gray-100 px-4 py-3 flex items-center justify-between shadow-sm">
      <div>
        <p className="text-xs text-gray-400 uppercase tracking-wide">Pedido {transaction.mid}</p>
        <p className="text-lg font-bold text-gray-900 leading-tight">{formatted}</p>
      </div>
      <div className="text-right">
        <p className="text-xs text-gray-400">Vendedor</p>
        <p className="text-sm font-medium text-gray-700">{transaction.counterparty.name}</p>
      </div>
    </header>
  )
}
```

- [ ] **Step 2: Commit**

```powershell
git add src/components/TransactionHeader.jsx
git commit -m "feat: add TransactionHeader component"
```

---

## Task 5: HelperBanner

**Files:**
- Create: `src/components/HelperBanner.jsx`

- [ ] **Step 1: Crear el componente**

Crear `src/components/HelperBanner.jsx`:

```jsx
import { useState } from 'react'

const SEVERITY_STYLES = {
  info:    'bg-blue-50 border-blue-200 text-blue-800',
  warning: 'bg-amber-50 border-amber-200 text-amber-800',
  error:   'bg-red-50 border-red-200 text-red-800',
}

const SEVERITY_ICONS = {
  info:    'ℹ',
  warning: '⚠',
  error:   '✕',
}

export function HelperBanner({ helper }) {
  const [dismissed, setDismissed] = useState(false)

  if (!helper || dismissed) return null

  const styles = SEVERITY_STYLES[helper.severity] ?? SEVERITY_STYLES.info
  const icon   = SEVERITY_ICONS[helper.severity] ?? 'ℹ'

  return (
    <div className={`mx-4 mt-3 rounded-xl border p-3 flex gap-3 items-start ${styles}`}>
      <span className="text-base mt-0.5 shrink-0">{icon}</span>
      <div className="flex-1 min-w-0">
        <p className="font-semibold text-sm">{helper.title}</p>
        <p className="text-sm mt-0.5 opacity-80">{helper.message}</p>
      </div>
      {helper.dismissible && (
        <button
          onClick={() => setDismissed(true)}
          className="shrink-0 text-lg leading-none opacity-60 hover:opacity-100"
          aria-label="Cerrar"
        >
          ×
        </button>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```powershell
git add src/components/HelperBanner.jsx
git commit -m "feat: add HelperBanner component"
```

---

## Task 6: Checkpoint wrapper

**Files:**
- Create: `src/components/checkpoints/Checkpoint.jsx`

- [ ] **Step 1: Crear el componente**

Crear `src/components/checkpoints/Checkpoint.jsx`:

```jsx
export function Checkpoint({ number, title, isActive, isCompleted, children }) {
  if (isCompleted) {
    return (
      <div className="mx-4 my-2 rounded-2xl border border-green-200 bg-green-50 px-4 py-3 flex items-center gap-3">
        <span className="w-7 h-7 rounded-full bg-green-500 flex items-center justify-center text-white text-sm font-bold shrink-0">✓</span>
        <span className="text-sm font-medium text-green-700">{title}</span>
      </div>
    )
  }

  if (!isActive) {
    return (
      <div className="mx-4 my-2 rounded-2xl border border-gray-100 bg-white px-4 py-3 flex items-center gap-3 opacity-40">
        <span className="w-7 h-7 rounded-full border-2 border-gray-300 flex items-center justify-center text-gray-400 text-sm font-bold shrink-0">{number}</span>
        <span className="text-sm font-medium text-gray-500">{title}</span>
      </div>
    )
  }

  return (
    <div className="mx-4 my-2 rounded-2xl border border-gray-200 bg-white px-4 py-4 shadow-sm">
      <div className="flex items-center gap-3 mb-4">
        <span className="w-7 h-7 rounded-full bg-gray-900 flex items-center justify-center text-white text-sm font-bold shrink-0">{number}</span>
        <span className="text-base font-semibold text-gray-900">{title}</span>
      </div>
      {children}
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```powershell
git add src/components/checkpoints/Checkpoint.jsx
git commit -m "feat: add Checkpoint wrapper component"
```

---

## Task 7: CheckpointTransfer (Checkpoint 1)

**Files:**
- Create: `src/components/checkpoints/CheckpointTransfer.jsx`

- [ ] **Step 1: Crear el componente**

Crear `src/components/checkpoints/CheckpointTransfer.jsx`:

```jsx
import { useState } from 'react'

function truncateCBU(cbu) {
  return cbu.slice(0, 8) + '···' + cbu.slice(-4)
}

function BankAccountCard({ transfer, currency, amount }) {
  const [copied, setCopied] = useState(null)
  const [expanded, setExpanded] = useState(false)

  const formattedAmount = new Intl.NumberFormat('es-AR', {
    style: 'currency',
    currency,
    maximumFractionDigits: 0,
  }).format(amount)

  function copyToClipboard(text, field) {
    navigator.clipboard.writeText(text).then(() => {
      setCopied(field)
      setTimeout(() => setCopied(null), 2000)
    })
  }

  return (
    <div className="space-y-3">
      <div>
        <p className="text-xs text-gray-400 mb-1">Enviá exactamente este monto</p>
        <button
          onClick={() => copyToClipboard(String(amount), 'amount')}
          className="w-full text-left bg-gray-50 rounded-xl px-4 py-3 flex items-center justify-between group"
        >
          <span className="text-2xl font-bold text-gray-900">{formattedAmount}</span>
          <span className="text-xs text-gray-400 group-hover:text-gray-600">
            {copied === 'amount' ? '¡Copiado!' : 'Copiar'}
          </span>
        </button>
      </div>

      <div>
        <p className="text-xs text-gray-400 mb-1">A esta cuenta</p>
        <div className="bg-gray-50 rounded-xl px-4 py-3 space-y-2">
          <div className="flex items-center justify-between">
            <span className="font-semibold text-gray-800 text-sm">{transfer.bank}</span>
            <span className="text-xs text-gray-400">{transfer.accountType}</span>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-600 font-mono">
              {expanded ? transfer.cbu : truncateCBU(transfer.cbu)}
            </span>
            <div className="flex gap-2">
              <button
                onClick={() => setExpanded(e => !e)}
                className="text-xs text-gray-400 hover:text-gray-600"
              >
                {expanded ? 'Ocultar' : 'Ver CBU'}
              </button>
              <button
                onClick={() => copyToClipboard(transfer.cbu, 'cbu')}
                className="text-xs text-brand-600 font-medium hover:text-brand-700"
              >
                {copied === 'cbu' ? '¡Copiado!' : 'Copiar CBU'}
              </button>
            </div>
          </div>

          {transfer.alias && (
            <div className="flex items-center justify-between">
              <span className="text-xs text-gray-500">Alias: {transfer.alias}</span>
              <button
                onClick={() => copyToClipboard(transfer.alias, 'alias')}
                className="text-xs text-brand-600 font-medium hover:text-brand-700"
              >
                {copied === 'alias' ? '¡Copiado!' : 'Copiar alias'}
              </button>
            </div>
          )}

          <div className="pt-1 border-t border-gray-200">
            <span className="text-xs text-gray-500">Titular: {transfer.holder}</span>
          </div>
        </div>
      </div>
    </div>
  )
}

export function CheckpointTransfer({ transaction }) {
  const [showCantPay, setShowCantPay] = useState(false)
  const transfers = transaction.directTransfers1

  return (
    <div className="space-y-4">
      {transfers.map((transfer, i) => (
        <div key={transfer.id}>
          {transfers.length > 1 && (
            <p className="text-xs text-gray-400 mb-2">{i + 1} de {transfers.length}</p>
          )}
          <BankAccountCard
            transfer={transfer}
            currency={transaction.currency}
            amount={transaction.amount}
          />
        </div>
      ))}

      <div className="pt-2">
        {!showCantPay ? (
          <button
            onClick={() => setShowCantPay(true)}
            className="text-sm text-gray-400 hover:text-gray-600 underline"
          >
            ¿No podés pagar con esta cuenta? Ver opciones →
          </button>
        ) : (
          <div className="bg-amber-50 rounded-xl p-3 text-sm text-amber-800 border border-amber-200">
            <p className="font-medium mb-1">Opciones alternativas</p>
            <p className="text-xs opacity-80">Contactá al vendedor para acordar otro medio de pago o cancelar la operación.</p>
          </div>
        )}
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```powershell
git add src/components/checkpoints/CheckpointTransfer.jsx
git commit -m "feat: add CheckpointTransfer component with copy-to-clipboard"
```

---

## Task 8: CheckpointConfirm (Checkpoint 2)

**Files:**
- Create: `src/components/checkpoints/CheckpointConfirm.jsx`

- [ ] **Step 1: Crear el componente**

Crear `src/components/checkpoints/CheckpointConfirm.jsx`:

```jsx
export function CheckpointConfirm() {
  return (
    <div className="space-y-3">
      <p className="text-sm text-gray-600">
        Una vez que hiciste la transferencia, confirmalo acá. El vendedor recibirá un aviso inmediato.
      </p>
      <div className="flex gap-2 items-start bg-amber-50 rounded-xl px-3 py-2 border border-amber-200">
        <span className="text-amber-500 mt-0.5 shrink-0">⚠</span>
        <p className="text-xs text-amber-700">
          Hacelo solo si ya transferiste el dinero. Esta acción avisa al vendedor que el pago fue enviado.
        </p>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```powershell
git add src/components/checkpoints/CheckpointConfirm.jsx
git commit -m "feat: add CheckpointConfirm component"
```

---

## Task 9: CheckpointProof (Checkpoint 3)

**Files:**
- Create: `src/components/checkpoints/CheckpointProof.jsx`

- [ ] **Step 1: Crear el componente**

Crear `src/components/checkpoints/CheckpointProof.jsx`:

```jsx
import { useState, useRef } from 'react'

export function CheckpointProof() {
  const [file, setFile] = useState(null)
  const inputRef = useRef()

  function handleFile(e) {
    const selected = e.target.files[0]
    if (selected) setFile(selected)
  }

  function removeFile() {
    setFile(null)
    inputRef.current.value = ''
  }

  return (
    <div className="space-y-3">
      <p className="text-sm text-gray-600">
        Adjuntá el comprobante de transferencia. Puede ser una captura de pantalla o PDF.
      </p>

      <input
        ref={inputRef}
        type="file"
        accept="image/*,.pdf"
        onChange={handleFile}
        className="hidden"
        id="proof-input"
      />

      {!file ? (
        <label
          htmlFor="proof-input"
          className="flex flex-col items-center justify-center w-full h-24 rounded-xl border-2 border-dashed border-gray-200 cursor-pointer hover:border-gray-400 hover:bg-gray-50 transition-colors"
        >
          <span className="text-2xl text-gray-300">+</span>
          <span className="text-sm text-gray-400 mt-1">Agregar archivo</span>
        </label>
      ) : (
        <div className="flex items-center gap-3 bg-gray-50 rounded-xl px-4 py-3 border border-gray-200">
          <span className="text-xl">📄</span>
          <span className="text-sm text-gray-700 flex-1 truncate">{file.name}</span>
          <button
            onClick={removeFile}
            className="text-gray-400 hover:text-red-500 text-lg leading-none"
            aria-label="Eliminar archivo"
          >
            ✕
          </button>
        </div>
      )}

      <p className="text-xs text-gray-400">Opcional pero recomendado — ayuda a resolver disputas.</p>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```powershell
git add src/components/checkpoints/CheckpointProof.jsx
git commit -m "feat: add CheckpointProof component with file upload"
```

---

## Task 10: FloatingCTA

**Files:**
- Create: `src/components/FloatingCTA.jsx`

- [ ] **Step 1: Crear el componente**

Crear `src/components/FloatingCTA.jsx`:

```jsx
import { CHECKPOINT } from '../data/mockTransaction'

const CTA_CONFIG = {
  [CHECKPOINT.TRANSFER]: {
    label: 'Ya vi los datos, continuar',
    sublabel: null,
  },
  [CHECKPOINT.CONFIRM]: {
    label: 'Ya transferí, avisar al vendedor',
    sublabel: 'El vendedor recibirá un aviso',
  },
  [CHECKPOINT.PROOF]: {
    label: 'Listo, enviar pedido',
    sublabel: null,
  },
  [CHECKPOINT.DONE]: null,
}

export function FloatingCTA({ active, onAdvance }) {
  const config = CTA_CONFIG[active]
  if (!config) return null

  return (
    <div className="fixed bottom-0 left-0 right-0 z-20 px-4 pb-6 pt-3 bg-gradient-to-t from-white via-white to-transparent">
      <button
        onClick={onAdvance}
        className="w-full bg-gray-900 hover:bg-gray-700 active:scale-95 text-white font-semibold rounded-2xl py-4 text-base transition-all"
      >
        {config.label}
      </button>
      {config.sublabel && (
        <p className="text-center text-xs text-gray-400 mt-2">{config.sublabel}</p>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```powershell
git add src/components/FloatingCTA.jsx
git commit -m "feat: add FloatingCTA component"
```

---

## Task 11: BuyerPage — página principal del comprador

**Files:**
- Create: `src/pages/BuyerPage.jsx`

- [ ] **Step 1: Crear la página**

Crear `src/pages/BuyerPage.jsx`:

```jsx
import { TransactionHeader }    from '../components/TransactionHeader'
import { HelperBanner }         from '../components/HelperBanner'
import { FloatingCTA }          from '../components/FloatingCTA'
import { Checkpoint }           from '../components/checkpoints/Checkpoint'
import { CheckpointTransfer }   from '../components/checkpoints/CheckpointTransfer'
import { CheckpointConfirm }    from '../components/checkpoints/CheckpointConfirm'
import { CheckpointProof }      from '../components/checkpoints/CheckpointProof'
import { useCheckpointState }   from '../hooks/useCheckpointState'
import { mockTransaction, CHECKPOINT } from '../data/mockTransaction'

export function BuyerPage() {
  const { active, advance, isCompleted } = useCheckpointState()

  if (active === CHECKPOINT.DONE) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center px-4 text-center">
        <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center text-3xl mb-4">✓</div>
        <h2 className="text-xl font-bold text-gray-900 mb-2">¡Todo listo!</h2>
        <p className="text-sm text-gray-500">Le avisamos al vendedor. Esperá su confirmación.</p>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 pb-32">
      <TransactionHeader transaction={mockTransaction} />
      <HelperBanner helper={mockTransaction.helper} />

      <div className="mt-3 space-y-1">
        <Checkpoint
          number={1}
          title="Transferí el dinero"
          isActive={active === CHECKPOINT.TRANSFER}
          isCompleted={isCompleted(CHECKPOINT.TRANSFER)}
        >
          <CheckpointTransfer transaction={mockTransaction} />
        </Checkpoint>

        <Checkpoint
          number={2}
          title="Avisá que pagaste"
          isActive={active === CHECKPOINT.CONFIRM}
          isCompleted={isCompleted(CHECKPOINT.CONFIRM)}
        >
          <CheckpointConfirm />
        </Checkpoint>

        <Checkpoint
          number={3}
          title="Subí tu comprobante"
          isActive={active === CHECKPOINT.PROOF}
          isCompleted={isCompleted(CHECKPOINT.PROOF)}
        >
          <CheckpointProof />
        </Checkpoint>
      </div>

      <FloatingCTA active={active} onAdvance={advance} />
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```powershell
git add src/pages/BuyerPage.jsx
git commit -m "feat: add BuyerPage assembling all checkpoints"
```

---

## Task 12: SellerPage — vista del vendedor

**Files:**
- Create: `src/components/seller/SellerView.jsx`
- Create: `src/pages/SellerPage.jsx`

- [ ] **Step 1: Crear SellerView**

Crear `src/components/seller/SellerView.jsx`:

```jsx
const STATUS_CONFIG = {
  waiting: {
    icon: '◷',
    iconClass: 'text-gray-300',
    labelClass: 'text-gray-400',
  },
  done: {
    icon: '✓',
    iconClass: 'text-green-500',
    labelClass: 'text-green-700',
  },
}

function SellerCheckpoint({ status, label }) {
  const config = STATUS_CONFIG[status]
  return (
    <div className="flex items-center gap-3 px-4 py-3">
      <span className={`w-7 h-7 rounded-full border-2 border-current flex items-center justify-center text-sm font-bold shrink-0 ${config.iconClass}`}>
        {config.icon}
      </span>
      <span className={`text-sm font-medium ${config.labelClass}`}>{label}</span>
    </div>
  )
}

export function SellerView({ buyerCheckpoint }) {
  const transferDone = ['confirm', 'proof', 'done'].includes(buyerCheckpoint)
  const confirmDone  = ['proof', 'done'].includes(buyerCheckpoint)
  const proofDone    = buyerCheckpoint === 'done'

  return (
    <div className="mx-4 mt-3 rounded-2xl border border-gray-200 bg-white divide-y divide-gray-100">
      <SellerCheckpoint
        status={transferDone ? 'done' : 'waiting'}
        label={transferDone ? 'Comprador vio los datos de transferencia' : 'Esperando que el comprador vea los datos'}
      />
      <SellerCheckpoint
        status={confirmDone ? 'done' : 'waiting'}
        label={confirmDone ? 'Comprador avisó que pagó' : 'Comprador aún no avisó que pagó'}
      />
      <SellerCheckpoint
        status={proofDone ? 'done' : 'waiting'}
        label={proofDone ? 'Comprobante subido' : 'Sin comprobante todavía'}
      />
    </div>
  )
}
```

- [ ] **Step 2: Crear SellerPage**

Crear `src/pages/SellerPage.jsx`:

```jsx
import { TransactionHeader } from '../components/TransactionHeader'
import { HelperBanner }      from '../components/HelperBanner'
import { SellerView }        from '../components/seller/SellerView'
import { mockTransaction }   from '../data/mockTransaction'

export function SellerPage({ buyerCheckpoint = 'transfer' }) {
  return (
    <div className="min-h-screen bg-gray-50">
      <TransactionHeader transaction={mockTransaction} />
      <HelperBanner helper={mockTransaction.helper} />

      <div className="mt-4 mx-4">
        <p className="text-xs text-gray-400 uppercase tracking-wide mb-2">Estado del pago</p>
      </div>

      <SellerView buyerCheckpoint={buyerCheckpoint} />

      <div className="mx-4 mt-4 text-center">
        <p className="text-xs text-gray-400">Esta vista se actualiza automáticamente.</p>
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Commit**

```powershell
git add src/components/seller/ src/pages/SellerPage.jsx
git commit -m "feat: add SellerPage and SellerView components"
```

---

## Task 13: App.jsx con toggle comprador/vendedor

**Files:**
- Modify: `src/App.jsx`
- Modify: `src/main.jsx`

- [ ] **Step 1: Reemplazar App.jsx**

Reemplazar `src/App.jsx` completo:

```jsx
import { useState } from 'react'
import { BuyerPage }  from './pages/BuyerPage'
import { SellerPage } from './pages/SellerPage'

export default function App() {
  const [view, setView] = useState('buyer')

  return (
    <div className="max-w-sm mx-auto min-h-screen relative">
      {/* Toggle de demo */}
      <div className="fixed top-0 right-0 z-30 m-3">
        <div className="bg-black/70 backdrop-blur rounded-full flex text-xs overflow-hidden">
          <button
            onClick={() => setView('buyer')}
            className={`px-3 py-1.5 transition-colors ${view === 'buyer' ? 'bg-white text-black font-semibold' : 'text-white'}`}
          >
            Comprador
          </button>
          <button
            onClick={() => setView('seller')}
            className={`px-3 py-1.5 transition-colors ${view === 'seller' ? 'bg-white text-black font-semibold' : 'text-white'}`}
          >
            Vendedor
          </button>
        </div>
      </div>

      {view === 'buyer' ? <BuyerPage /> : <SellerPage />}
    </div>
  )
}
```

- [ ] **Step 2: Reemplazar main.jsx**

Reemplazar `src/main.jsx` completo:

```jsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
)
```

- [ ] **Step 3: Levantar el servidor y verificar**

```powershell
npm run dev
```

Verificar en `http://localhost:5173`:
- El toggle comprador/vendedor funciona
- El comprador puede avanzar por los 3 checkpoints
- La vista del vendedor muestra los estados en espera
- La pantalla se ve bien en ancho mobile (≤ 390px)

- [ ] **Step 4: Correr todos los tests**

```powershell
npx vitest run
```

Esperado: todos los tests PASS

- [ ] **Step 5: Commit final**

```powershell
git add src/App.jsx src/main.jsx
git commit -m "feat: wire up App with buyer/seller toggle for demo"
```

---

## Self-Review

**Cobertura del spec:**
- ✅ Header fijo con monto, contraparte y transaction_mid
- ✅ Banner de helper con severidad y dismissible/no-dismissible
- ✅ Checkpoint 1: datos bancarios, copy CBU/monto, "no puedo pagar"
- ✅ Checkpoint 2: confirmación con fricción deliberada
- ✅ Checkpoint 3: upload de comprobante
- ✅ CTA flotante que cambia por checkpoint activo
- ✅ Estado completado colapsado (verde con ✓)
- ✅ Vista del vendedor en solo lectura con estados
- ✅ Mobile-first con max-width contenido

**Tipos consistentes:**
- `CHECKPOINT.TRANSFER / CONFIRM / PROOF / DONE` se usa uniformemente en hook, FloatingCTA y SellerView
- `mockTransaction.directTransfers1` es array — CheckpointTransfer itera correctamente

**Unknowns del spec no bloqueantes para el prototipo:**
- Persistencia real de `marked_as_sent`: en el prototipo es estado local, suficiente para la demo
- Catálogo de `direct_transfer_action`: simplificado a "contactar al vendedor"
- `transaction_helpers` opcionales: el mock tiene `helper: null` por defecto, fácil de activar para demo
