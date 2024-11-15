resource "aws_vpc" "eks" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "foyer-vpc"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.eks.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet1"
  }
}


resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.eks.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.eks.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "foyer_route" {
  vpc_id = aws_vpc.eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.eks.id
  route_table_id = aws_route_table.foyer_route.id
}

# resource "aws_route_table_association" "association" {
#   subnet_id      = aws_subnet.subnet1.id
#   route_table_id = aws_route_table.foyer_route.id
# }
# resource "aws_route_table_association" "association2" {
#   subnet_id      = aws_subnet.subnet2.id
#   route_table_id = aws_route_table.foyer_route.id
# }

resource "aws_eks_cluster" "foyer_eks_cluster" {
  name     = "foyer-eks-cluster"
  role_arn = "arn:aws:iam::208904549529:role/LabRole"

  vpc_config {
    subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }
}



resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.eks.id  # Utilisation de la variable pour l'ID du VPC

  ingress {
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}

resource "aws_eks_node_group" "node-g" {
  cluster_name    = aws_eks_cluster.foyer_eks_cluster.name
  node_group_name = "foyer-node-group"
  node_role_arn   = "arn:aws:iam::208904549529:role/LabRole"
  subnet_ids      = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  instance_types = ["t3.small"]
  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }
}