# TypeScript Coding Guidelines

## Principles

- Prefer readability over brevity
- Design with types first
- Avoid runtime bugs through static typing
- Keep functions small and pure
- Prefer explicitness over magic


# tsconfig

```json
{
  "compilerOptions": {
    "target": "ES2023",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",

    "strict": true,

    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,

    "verbatimModuleSyntax": true,
    "isolatedModules": true
  }
}
```


# Imports

```ts
import type { User } from "./types.js"
```

- Use named exports
- Use `type` imports
- Prefer ESM
- Use `node:` prefix for Node.js modules


# Types

```ts
type User = {
  id: string
  name: string
}
```

- Prefer `type` over `interface`
- Never use `any`
- Use `unknown` for unsafe values
- Prefer union types
- Prefer literal types over booleans
- Avoid `enum`

```ts
const ROLE = {
  ADMIN: "admin",
  USER: "user"
} as const
```


# Functions

```ts
const createUser = ({ name }: { name: string }): User => {
  return {
    id: crypto.randomUUID(),
    name
  }
}
```

- Prefer arrow functions
- Public functions require explicit return types
- Prefer object parameters
- Separate side effects from logic


# Async

```ts
const [user, profile] = await Promise.all([
  fetchUser(),
  fetchProfile()
])
```

- Use `Promise.all` for concurrency
- Mark intentional fire-and-forget calls with `void`

```ts
void sendAnalytics()
```


# Nullability

```ts
const name = input ?? "guest"
```

- Prefer `undefined` over `null`
- Use optional chaining
- Use nullish coalescing (`??`)


# Errors

```ts
throw new Error("invalid state")
```

- Only throw `Error`
- Create domain-specific error classes when needed


# Naming

| Target | Style |
|---|---|
| variables/functions | camelCase |
| types/components | PascalCase |
| constants | UPPER_SNAKE_CASE |
| files | kebab-case.ts |
| booleans | is/has/can prefix |


# React

```tsx
type Props = {
  title: string
}

const Button = ({ title }: Props) => {
  return <button>{title}</button>
}
```

- Do not use `React.FC`
- Prefer composition over inheritance
- Minimize `useEffect`


# Node.js

```json
{
  "type": "module"
}
```

```ts
import fs from "node:fs/promises"
```


# Forbidden

- `any`
- non-null assertion (`!`)
- implicit `any`
- large functions
- deep nesting
- inheritance-heavy design


# Recommended Libraries

- ESLint
- Prettier
- Zod
- Vitest
- Playwright
- date-fns
- pino


# Runtime Validation

```ts
const UserSchema = z.object({
  id: z.string(),
  name: z.string()
})
```

- Validate all external input
- TypeScript types are not runtime safety


# Exhaustiveness

```ts
switch (role) {
  case "admin":
    break

  case "user":
    break

  default:
    role satisfies never
}
```

- Always enforce exhaustive checks