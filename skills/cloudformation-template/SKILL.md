---
name: cloudformation-template
description: AWS CloudFormation テンプレートの基本設計。セクション構成・パラメータ・組み込み関数・リソース属性・ベストプラクティス。
---

# CloudFormation Template Design Guide

AWS のインフラをコード（IaC）として定義する CloudFormation テンプレートの基本的な書き方。
YAML と JSON が使えるが、コメントやアンカーが使え可読性が高い **YAML を推奨**する。

## テンプレートの全体構造

テンプレートは複数のセクションで構成される。`Resources` のみ必須で、それ以外は任意。

```yaml
AWSTemplateFormatVersion: "2010-09-09"   # 任意。値は固定でこの1種類のみ
Description: "VPC と EC2 を作成するスタック"  # 任意。最大 1024 文字

Metadata: {}      # 任意。テンプレートに関する追加情報
Parameters: {}    # 任意。スタック作成時に渡す入力値
Rules: {}         # 任意。パラメータの組み合わせを検証
Mappings: {}      # 任意。キーと値のルックアップテーブル
Conditions: {}    # 任意。リソース作成可否などの条件
Transform: []     # 任意。マクロ（SAM, Include など）を適用
Resources: {}     # 必須。作成する AWS リソース
Outputs: {}       # 任意。スタックの出力値
```

### セクションの役割

| セクション | 役割 |
|-----------|------|
| `AWSTemplateFormatVersion` | テンプレート形式のバージョン。常に `"2010-09-09"` |
| `Description` | テンプレートの説明文 |
| `Metadata` | パラメータの表示順など追加メタ情報 |
| `Parameters` | 実行時に渡す値。環境ごとの差異を吸収する |
| `Rules` | パラメータが特定条件を満たすか検証する |
| `Mappings` | リージョンや環境ごとの定数を引くルックアップテーブル |
| `Conditions` | 条件に応じてリソース作成や値を切り替える |
| `Transform` | マクロを適用する（SAM の `AWS::Serverless-2016-10-31` など） |
| `Resources` | **必須**。EC2、S3 などの実体を定義 |
| `Outputs` | 作成したリソースの ID や ARN を出力・エクスポートする |

## Resources（リソース）

最も重要な必須セクション。論理 ID をキーに、リソースを定義する。

```yaml
Resources:
  MyBucket:                          # 論理 ID（テンプレート内で一意）
    Type: AWS::S3::Bucket            # リソースタイプ
    Properties:                      # リソース固有のプロパティ
      BucketName: my-app-bucket-12345
      VersioningConfiguration:
        Status: Enabled
```

- **論理 ID**: テンプレート内で参照に使う名前。英数字のみ、スタック内で一意
- **Type**: `AWS::サービス名::リソース種別` の形式
- **Properties**: リソースごとに定義されたプロパティ群

## Parameters（パラメータ）

スタック作成・更新時に値を渡し、テンプレートを再利用可能にする。

```yaml
Parameters:
  EnvironmentName:
    Type: String
    Default: dev
    AllowedValues: [dev, staging, prod]
    Description: デプロイ環境名

  InstanceType:
    Type: String
    Default: t3.micro
    AllowedValues: [t3.micro, t3.small, t3.medium]

  DbPassword:
    Type: String
    NoEcho: true                     # コンソールやログに値を表示しない
    MinLength: 8
    MaxLength: 41
    AllowedPattern: "[a-zA-Z0-9]+"

  VpcId:
    Type: AWS::EC2::VPC::Id           # AWS 固有型は実在する値を検証・選択できる
```

### 主なパラメータ型

| 型 | 用途 |
|----|------|
| `String` | 文字列 |
| `Number` | 数値 |
| `List<Number>` | 数値のリスト |
| `CommaDelimitedList` | カンマ区切りの文字列リスト |
| `AWS::EC2::KeyPair::KeyName` | 既存のキーペア名（実在検証あり） |
| `AWS::EC2::VPC::Id` | 既存の VPC ID |
| `AWS::EC2::Subnet::Id` | 既存のサブネット ID |
| `AWS::SSM::Parameter::Value<String>` | Parameter Store の値を解決 |

### 制約プロパティ

- `Default`: デフォルト値
- `AllowedValues`: 許可する値のリスト
- `AllowedPattern`: 正規表現による検証
- `MinLength` / `MaxLength`: 文字列長
- `MinValue` / `MaxValue`: 数値範囲
- `NoEcho`: パスワードなど秘匿値を隠す
- `ConstraintDescription`: 制約違反時のメッセージ

## 組み込み関数（Intrinsic Functions）

実行時まで値が確定しないプロパティに使う。短縮形（`!`）の利用を推奨。

### Ref — 値の参照

パラメータの値、またはリソースの既定の戻り値（多くは物理 ID）を返す。

```yaml
BucketName: !Ref EnvironmentName        # パラメータの値
VpcId: !Ref MyVPC                        # リソースの ID
```

### Fn::GetAtt — リソース属性の取得

リソースの属性（ARN、エンドポイントなど）を返す。

```yaml
Value: !GetAtt MyBucket.Arn
Value: !GetAtt MyDB.Endpoint.Address     # ネストした属性はドット区切り
```

### Fn::Sub — 文字列の変数展開

`${}` で変数を埋め込む。`!Join` より読みやすい。

```yaml
BucketName: !Sub "${EnvironmentName}-app-bucket"
Arn: !Sub "arn:${AWS::Partition}:s3:::${MyBucket}"
# 変数マップを明示する形式
UserData: !Sub
  - "echo ${Greeting} on ${AWS::Region}"
  - Greeting: Hello
```

### Fn::Join — 文字列の連結

区切り文字でリストを連結する。

```yaml
Value: !Join ["-", [!Ref EnvironmentName, "app", "bucket"]]
```

### Fn::FindInMap — マッピングの参照

`Mappings` から値を引く。

```yaml
ImageId: !FindInMap [RegionMap, !Ref "AWS::Region", AMI]
```

### Fn::GetAZs / Fn::Select — リストの取得と選択

```yaml
AvailabilityZone: !Select [0, !GetAZs ""]   # リージョンの最初の AZ
```

### 条件・その他の関数

- `Fn::If`, `Fn::Equals`, `Fn::And`, `Fn::Or`, `Fn::Not`: 条件評価
- `Fn::ImportValue`: 別スタックがエクスポートした値を取り込む
- `Fn::Split`: 文字列をリストに分割
- `Fn::Base64`: UserData などを Base64 エンコード
- `Fn::Cidr`: CIDR ブロックを分割

## 擬似パラメータ（Pseudo Parameters）

定義不要で `!Ref` できる、AWS 提供の組み込み変数。

| 擬似パラメータ | 内容 |
|---------------|------|
| `AWS::Region` | スタックのリージョン（例: `ap-northeast-1`） |
| `AWS::AccountId` | AWS アカウント ID |
| `AWS::StackName` | スタック名 |
| `AWS::StackId` | スタックの ID（ARN） |
| `AWS::Partition` | パーティション（`aws`, `aws-cn` など） |
| `AWS::URLSuffix` | ドメインサフィックス（`amazonaws.com`） |
| `AWS::NoValue` | 指定するとそのプロパティ自体を削除する |

## Mappings（マッピング）

リージョンや環境ごとの定数を引くルックアップテーブル。組み込み関数は使えず、固定値のみ。

```yaml
Mappings:
  RegionMap:
    ap-northeast-1:
      AMI: ami-0123456789abcdef0
    us-east-1:
      AMI: ami-0fedcba9876543210
Resources:
  MyInstance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !FindInMap [RegionMap, !Ref "AWS::Region", AMI]
```

## Conditions（条件）

環境に応じてリソースの作成可否やプロパティを切り替える。

```yaml
Conditions:
  IsProd: !Equals [!Ref EnvironmentName, prod]

Resources:
  ProdOnlyBucket:
    Type: AWS::S3::Bucket
    Condition: IsProd                  # IsProd が true のときだけ作成

  MyInstance:
    Type: AWS::EC2::Instance
    Properties:
      # 条件で値を出し分ける
      InstanceType: !If [IsProd, t3.large, t3.micro]
```

## Outputs（出力）

作成したリソースの値を出力し、他スタックから参照できるようエクスポートする。

```yaml
Outputs:
  BucketArn:
    Description: 作成したバケットの ARN
    Value: !GetAtt MyBucket.Arn

  VpcId:
    Value: !Ref MyVPC
    Export:
      Name: !Sub "${AWS::StackName}-VpcId"   # 他スタックが ImportValue で参照
```

別スタックでの取り込み：

```yaml
SubnetVpcId: !ImportValue my-network-stack-VpcId
```

## リソース属性（Resource Attributes）

`Properties` と並べて指定する、リソースの振る舞いを制御する属性。

### DependsOn — 作成順序

リソース間の依存を明示し、作成・削除順を制御する。

```yaml
MyInstance:
  Type: AWS::EC2::Instance
  DependsOn: MyGatewayAttachment      # 複数ならリストで指定
```

### DeletionPolicy — 削除時の挙動

スタック削除時にリソースを保持・バックアップする。

```yaml
MyDatabase:
  Type: AWS::RDS::DBInstance
  DeletionPolicy: Snapshot            # Delete（既定）/ Retain / Snapshot
```

- `Delete`: 既定。リソースを削除
- `Retain`: スタック削除後もリソースを残す
- `Snapshot`: 削除前にスナップショットを取得（RDS, EBS, Redshift など対応リソースのみ）

### UpdateReplacePolicy — 置換時の挙動

更新で**リソースが置換（再作成）される**際の旧リソースの扱い。値は `DeletionPolicy` と同じ。
DeletionPolicy とは適用場面が異なるため、データを持つリソースでは両方を指定するのが安全。

```yaml
MyDatabase:
  Type: AWS::RDS::DBInstance
  DeletionPolicy: Snapshot
  UpdateReplacePolicy: Snapshot
```

### CreationPolicy — 完了シグナル待ち

EC2 や Auto Scaling グループの初期化完了シグナル（`cfn-signal`）を待つ。

```yaml
MyInstance:
  Type: AWS::EC2::Instance
  CreationPolicy:
    ResourceSignal:
      Count: 1
      Timeout: PT15M                  # ISO8601 期間。15 分
```

### UpdatePolicy — 更新時の挙動

Auto Scaling グループなどのローリング更新方法を制御する。

## ベストプラクティス

- **Parameters / Mappings / Conditions で再利用可能に**: ハードコードを避け、環境差を吸収する
- **物理名はできるだけ指定しない**: `BucketName` などを固定すると更新時の置換や名前衝突の原因になる。CloudFormation の自動命名に任せる
- **クロススタック参照**: 値の共有は `Export` / `Fn::ImportValue`、または SSM Parameter Store を使う
- **NoEcho で秘匿**: パスワード等は `NoEcho: true`。実値は Secrets Manager / Parameter Store の動的参照（`{{resolve:...}}`）が望ましい
- **データ保持リソースには削除保護**: RDS / DynamoDB / S3 などには `DeletionPolicy` と `UpdateReplacePolicy` を設定
- **変更セット（Change Set）で事前確認**: 本番更新前に差分を確認してから実行する
- **スタックは適切に分割**: ネットワーク・データ・アプリなど変更頻度や責務で分ける
- **検証を習慣化**: `cfn-lint` や `aws cloudformation validate-template` で文法・規約をチェック

## 主要な CLI コマンド

```bash
# テンプレート検証
aws cloudformation validate-template --template-body file://template.yaml

# 変更セットの作成（差分確認）
aws cloudformation create-change-set \
  --stack-name my-stack --change-set-name my-change \
  --template-body file://template.yaml

# デプロイ（作成・更新を自動判定）
aws cloudformation deploy \
  --stack-name my-stack \
  --template-file template.yaml \
  --parameter-overrides EnvironmentName=prod \
  --capabilities CAPABILITY_NAMED_IAM

# スタック削除
aws cloudformation delete-stack --stack-name my-stack
```

完全なテンプレート例は [examples/template.yaml](examples/template.yaml) を参照。
