# WAF_ALB_ASG

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white) 
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Visual Studio Code](https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white)
![Git](https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white)
![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

## What is this? 
In this project I built a web application architecture on AWS using Terraform that is scalable. It features a custom VPC, public subnets, an Application Load Balancer, Auto Scaling Group, and EC2 instances. I also integrated WAF protection and security groups to ensure robust access control while supporting high availability and traffic spikes.

### Architecture

![Screenshot](/architecture-diagrams/ALB_ASG_WAF.png)

- VPC built with 2 public subnets, each in its own Availability Zone
- An internet gateway
- EC2 instances, inside a Target Group
- ASG pointing to Target Group, with a min, max and desired no. of EC2s
- 1 Route Table
- Web Application Firewall pointing to the ALB


### Prerequisites before installation 

1) You will need your AWS Credentials to hand. 
2) You will need your IP address for the WAF rule. You can check your ip by going to https://checkip.amazonaws.com/

### Installation

To install this code on your machine follow these steps: 
1) Download code onto your machine using .zip file or through git cli and open in a code editor 
2) If you will want to SSH into your EC2 hosts, create a keypair called "MY_EC2_INSTANCE_KEYPAIR"
3) Set up your AWS credentials as environment variables: 
- `export AWS_ACCESS_KEY_ID="your-access-key-id"` (this will set your access key in the terminal session)
- `export AWS_SECRET_ACCESS_KEY="your-secret"` (this will set your secret access key in the terminal session)
4) Then run the Terraform commands: 
- `terraform init`
- `terraform plan`
- `terraform apply` (select yes) 
5) When prompted for your ip address, provide it in the terminal and remember to put a **/32** at the end.

### Usage
Follow these steps to check its working: 
1) Either in the AWS console or through the output in your terminal, locate the ALB's DNS Name and see if you can connect to it using **http**. You should see a html message appear on your screen with the hostname ip and server ip.
2) If you want to SSH into one of your EC2 hosts you can now do so using the keypair you created.
3) To check if the Firewall is working, you can change the action in the `Rule for WAF` section (in file loadbalancer.tf) from "allow" to "block". If you're unable to connect it means its working correctly as its blocking your IP. Alternatively, without touching the code, you can turn on a VPN and try to connect to the ALB's DNS. You should be blocked automatically, showing the setup works. 
4) Once everything is working I highly recommend you run `terraform destroy` in order not to incurr fees. 


### Licensing 
MIT license