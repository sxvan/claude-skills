# Worked examples

Each pair does the same job twice: first the version that guards, then the version with nothing
left to guard. Numbers refer to the rules in `SKILL.md`.

## Return early instead of nesting (14)

Instead of this, where the real work sits two levels deep and the reader holds two open
conditions to reach it:

```python
def publish(post, user):
    if user.role is Role.ADMIN:
        if not post.is_published:
            post.publish()
            return post
```

Prefer this, where each exit is handled once and the main path runs unindented:

```python
def publish(post, user) -> Post:
    if user.role is not Role.ADMIN:
        raise PermissionError(user)
    if post.is_published:
        return post
    post.publish()
    return post
```

These early returns are not the silent guard of rule 5. Both states can really occur, and
raising or returning is what the caller wants.

## Validate once, at the boundary (2)

Instead of this, where every caller asks the same question and the answers drift apart:

```python
def send_welcome(user):
    if user is None:
        return
    if not user.email:
        return
    if "@" not in user.email:
        log.warning("bad email")
        return
    smtp.send(user.email, WELCOME)
```

Prefer this. An `Email` exists only if it parsed, so nothing downstream has anything to check:

```python
@dataclass(frozen=True)
class Email:
    address: str

    @staticmethod
    def parse(raw: str) -> Email | None:
        """The one place a raw string can fail. Callers deal with None here, once."""

def send_welcome(to: Email) -> None:
    smtp.send(to.address, WELCOME)
```

## Delete the guard the domain already rules out (1, 5)

Instead of this, with three checks for states that no code path can produce, which leaves the
reader unsure whether the author knew that:

```python
def total(order):
    if order is None:
        return 0
    if not order.lines:
        return 0
    return sum(line.amount for line in order.lines)
```

Prefer this. Orders are created with at least one line, callers always have one, and `sum`
already answers the empty case:

```python
def total(order: Order) -> Decimal:
    return sum(line.amount for line in order.lines)
```

If `order` really can be `None` at one call site, that caller handles it. The other twenty
shouldn't pay for it.

## Leave out the catch-all so the compiler finds the next case (10)

Instead of this, where adding a `"failed"` status still compiles and renders "Unknown" with no
warning:

```ts
function label(s: Status): string {
  switch (s) {
    case "queued":  return "Queued";
    case "running": return "Running";
    default:        return "Unknown";
  }
}
```

Prefer this, where the same addition is a compile error at every site that has to change:

```ts
type Status = "queued" | "running" | "done";

function label(s: Status): string {
  switch (s) {
    case "queued":  return "Queued";
    case "running": return "Running";
    case "done":    return "Done";
  }
}
```

## Data instead of control flow (9)

Instead of this, where a new format means a new code path:

```python
def mime_type(ext):
    if ext == ".png":
        return "image/png"
    elif ext in (".jpg", ".jpeg"):
        return "image/jpeg"
    else:
        return "application/octet-stream"
```

Prefer this, where a new format is one line of data:

```python
MIME_TYPES = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg"}

def mime_type(ext: str) -> str:
    return MIME_TYPES.get(ext, "application/octet-stream")
```
