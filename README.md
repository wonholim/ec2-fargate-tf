# ECS [EC2, Fargate]

- ECS Provisioning을 위한 레포지토리입니다.
- ECS는 EC2, Fargate 두가지 모드로 구성할 수 있습니다.
- ECS는 EC2 모드에서는 EC2 인스턴스를 직접 관리해야 하고, Fargate 모드에서는 EC2 인스턴스를 관리하지 않습니다.
- ECS Fargate를 사용하여 블루/그린 배포를 생성하는 모듈
- ECS EC2를 사용하여 블루/그린 배포를 생성하는 모듈
- 공용 및 사설 서브넷이 포함된 VPC를 생성하는 모듈

- Certificates는 별도로 등록해주셔야합니다.

- 그 외, DB 및 S3 등의 리소스는 별도로 생성해주셔야합니다.