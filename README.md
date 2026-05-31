# HCP Terraform — AWS Infrastructure Automation

> HCP Terraform과 GitHub(VCS)를 연동하여, 코드 push 시 AWS 인프라가 자동으로 배포되는 IaC 워크플로우 구축

## 개요

| 항목 | 내용 |
|------|------|
| **기간** | 2026.05 |
| **유형** | 팀 프로젝트 |
| **역할** | 조장 — HCP-GitHub 연동 구성, 배포 및 코드 리뷰 |
| **IaC 도구** | Terraform (HCL) |
| **상태 관리** | HCP Terraform (HashiCorp Cloud Platform) |
| **대상 클라우드** | AWS (서울 리전, ap-northeast-2) |

## 핵심 개념

| 개념 | 설명 |
|------|------|
| **IaC (Infrastructure as Code)** | 인프라를 콘솔 수작업이 아닌 코드로 정의·관리하는 방식 |
| **HCP Terraform** | Terraform 상태 파일(state)을 클라우드에서 관리하고 원격으로 plan/apply를 실행하는 HashiCorp 관리형 서비스 |
| **VCS-Driven Workflow** | GitHub 저장소와 HCP Terraform을 연동하여, push를 트리거로 자동 plan/apply가 실행되는 워크플로우 |

## 워크플로우

```
[개발자]
   │  git push
   ▼
[GitHub Repository] ── VCS 연동 ──▶ [HCP Terraform Workspace]
                                          │
                                          │ 1. 변경 자동 감지
                                          │ 2. terraform plan 자동 실행
                                          │ 3. terraform apply 자동 실행 (Auto Apply)
                                          ▼
                                    [AWS 인프라 반영]
```

코드를 GitHub에 push하면 HCP Terraform이 변경을 자동 감지하여 plan과 apply를 사람 개입 없이 실행, AWS 인프라에 반영합니다.

## Terraform 명령어 흐름

```bash
terraform init       # 작업 디렉토리 초기화 (provider 다운로드)
terraform validate   # .tf 파일 문법 검증
terraform plan       # 변경사항 미리보기
terraform apply      # 변경사항 적용
terraform destroy    # 리소스 제거
```

| 명령어 | 주요 옵션 |
|--------|----------|
| `terraform init` | `-upgrade` (provider 버전 업그레이드), `-reconfigure` (backend 재설정) |
| `terraform plan` | `-out=plan.tfplan` (결과 파일 저장), `-var-file=prod.tfvars` (변수 파일 지정) |
| `terraform apply` | `-auto-approve` (확인 단계 생략), `plan.tfplan` (plan 결과 적용) |

## 인프라 구성 (Terraform 모듈)

리소스별로 `.tf` 파일을 분리하여 관리

```
HCP-Terraform-HISTORY/
├── 1. Terraform Provider.tf   # Terraform & AWS Provider 설정
├── 2. VPC.tf                  # VPC
├── 3. Subnet.tf               # Subnet
├── 4. IGW.tf                  # Internet Gateway
├── 5. NGW.tf                  # NAT Gateway & EIP
├── 6. RT.tf                   # Routing Table & Routing
├── 7. Security Group.tf       # Security Group
├── 8. Key Pair.tf             # Key Pair
├── 9. EC2.tf                  # Bastion Instance
├── 10. RDS.tf                 # Subnet Group & Parameter Group & RDS
├── 11. S3.tf                  # S3 Bucket
├── 12. acm.tf                 # ACM (SSL/TLS 인증서)
├── 13. route53.tf             # Route53 Zone
├── 14. ALB.tf                 # Target Group & Listener & ALB
└── 15. AutoScaling.tf         # Launch Template & Auto Scaling
```

| 분류 | 리소스 |
|------|--------|
| **네트워크** | VPC, Subnet, IGW, NAT GW(EIP), Routing Table |
| **보안** | Security Group, Key Pair, ACM |
| **컴퓨팅** | EC2(Bastion), Launch Template, Auto Scaling |
| **데이터베이스** | RDS (Subnet Group, Parameter Group) |
| **스토리지** | S3 |
| **DNS / 부하분산** | Route53, ALB (Target Group, Listener) |

## HCP Terraform 연동 구성

```
1. HCP Terraform 조직(Organization) 및 워크스페이스(Workspace) 생성
2. 워크스페이스 타입: Version Control Workflow 선택
3. GitHub 저장소(HCP-Terraform-HISTORY) 연결
4. AWS 자격증명을 환경 변수로 등록 (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
5. Auto Apply 활성화 → push 시 승인 단계 없이 자동 배포
```

> 💡 상태 파일(`.tfstate`)을 로컬이 아닌 HCP Terraform에서 관리하므로, 팀 협업 시 상태 충돌을 방지하고 변경 이력을 중앙에서 추적할 수 있습니다.

## 검증 결과

- GitHub push → HCP Terraform 자동 plan/apply → AWS 인프라 반영 파이프라인 동작 확인
- 콘솔 수작업 없이 코드(IaC)만으로 AWS 인프라 전체 배포 검증 완료
- 팀 단위 코드 리뷰를 통한 인프라 코드 품질 관리

## 자료

[Terraform Project HISTORY.pdf](./docs/1_HISTORY_TerraformProject.pdf)
