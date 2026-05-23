# C# コーディング規約

## 言語機能

### new() の使い方

`var` は使用しない。左辺に型を書き、右辺は `new()` で省略:

```csharp
User user = new();
List<string> names = new();
Dictionary<string, int> dict = new();
List<User> list = users.Where(u => u.IsActive).ToList();
string result = GetValue();
```

### nullable reference types

csproj で有効化:

```xml
<Nullable>enable</Nullable>
```

```csharp
string name = "abc";   // null 不可
string? name = null;   // null 許可

// null 合体演算子
string display = name ?? "名無し";

// null 条件演算子
int? length = name?.Length;
```

### collection expression

```csharp
List<int> numbers = [1, 2, 3];
int[] values = [1, 2, 3];
string[] empty = [];

// スプレッド
int[] merged = [..a, ..b];
```

### pattern matching

```csharp
string message = code switch
{
    200 => "OK",
    404 => "Not Found",
    >= 500 => "Server Error",
    _ => "Unknown"
};

// 型パターン
string Describe(object obj) => obj switch
{
    int n when n > 0 => "正の整数",
    string s => $"文字列: {s}",
    null => "null",
    _ => "その他"
};

// プロパティパターン
if (user is { IsActive: true, Role: "admin" })
{
    // ...
}
```

### using の簡略化

```csharp
using StreamReader file = new(path);
using SqlConnection conn = new(connStr);
// スコープ終端で自動 Dispose
```

### LINQ

```csharp
List<User> adults = users
    .Where(u => u.Age >= 18)
    .OrderBy(u => u.Name)
    .ToList();

// メソッド構文を推奨（クエリ構文より読みやすい場面が多い）
int count = users.Count(u => u.IsActive);
User? first = users.FirstOrDefault(u => u.Id == id);
```

## 型定義

### file-scoped namespace

```csharp
namespace MyApp.Services;

class UserService
{
}
```

### record（不変データ）

値の等価性が必要なデータには `record` を使う:

```csharp
record User(string Name, int Age);

// with 式でコピー
User updated = user with { Age = 30 };
```

### init-only property / required

```csharp
public class User
{
    public required string Name { get; init; }
    public int Age { get; init; } = 0;
}

User user = new()
{
    Name = "Hikari"  // required なので必須
};
```

### primary constructor（C# 12）

```csharp
class UserService(IUserRepository repo, ILogger<UserService> logger)
{
    public async Task<User?> GetAsync(int id)
    {
        logger.LogInformation("Getting user {Id}", id);
        return await repo.FindAsync(id);
    }
}
```

## 非同期

### async / await

```csharp
// 戻り値なし → Task
async Task SaveAsync(User user) { ... }

// 戻り値あり → Task<T>
async Task<User?> FindAsync(int id) { ... }

// UI スレッドを不要にブロックしない
User? user = await repo.FindAsync(id);

// 並列実行
(ResultA a, ResultB b) = await (TaskA(), TaskB());
// または
await Task.WhenAll(task1, task2);
```

### ConfigureAwait

ライブラリコードでは `ConfigureAwait(false)`:

```csharp
string data = await httpClient.GetStringAsync(url).ConfigureAwait(false);
```

## API

### Minimal API

```csharp
WebApplication app = WebApplication.Create(args);

app.MapGet("/users/{id}", async (int id, IUserService svc) =>
{
    User? user = await svc.FindAsync(id);
    return user is null ? Results.NotFound() : Results.Ok(user);
});

app.Run();
```

### Results 型を使う

```csharp
// 直接オブジェクトを返さず Results を使う
Results.Ok(user)
Results.NotFound()
Results.BadRequest("Invalid input")
Results.Created($"/users/{user.Id}", user)
```

## エラー処理

### 例外は例外的な状況だけに使う

```csharp
// 通常フローには使わない
// NG: try { int.Parse(s) } catch { return 0; }

// OK: TryParse パターン
if (int.TryParse(s, out int value))
{
    // ...
}
```

### Result 型（失敗を戻り値で表す）

```csharp
record Result<T>(T? Value, string? Error)
{
    public bool IsSuccess => Error is null;
    public static Result<T> Ok(T value) => new(value, null);
    public static Result<T> Fail(string error) => new(default, error);
}
```

## その他

### string interpolation

```csharp
string msg = $"Hello, {name}!";

// 複数行は生文字列リテラル（C# 11）
string json = """
    {
        "name": "Hikari"
    }
    """;
```

### readonly / const

```csharp
// コンパイル時定数
const int MaxRetry = 3;

// インスタンスで変更不可
readonly List<string> _tags = [];
```

### 命名規則

| 対象 | 規則 | 例 |
|||--|
| クラス・メソッド・プロパティ | PascalCase | `UserService`, `GetAsync` |
| ローカル変数・引数 | camelCase | `userId`, `isActive` |
| プライベートフィールド | `_camelCase` | `_repository` |
| 定数 | PascalCase | `MaxRetry` |
| インターフェース | `I` プレフィックス | `IUserRepository` |
