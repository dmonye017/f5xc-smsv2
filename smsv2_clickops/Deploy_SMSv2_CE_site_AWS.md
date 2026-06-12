# How to Deploy an F5 Distributed Cloud Secure Mesh Site v2 in AWS (ClickOps)


## Prerequisites

- An AWS account with permissions to create EC2 instances, VPCs, and related resources
- An existing VPC, with two subnets, route tables, and internet gateway in AWS where the SMSv2 CE site will be deployed, or permissions to create a new VPC
- An Elastic IP address in AWS to associate with the SMSv2 CE site
- An F5 Distributed Cloud tenant with permissions to create and manage Secure Mesh Sites v2

## Steps
**1. Create a SMSv2 CE site object in F5 Distributed Cloud**
- Log into your F5 Distributed Cloud tenant
- In the F5 Distributed Cloud Console, select the **Multi-Cloud Network Connect** workspace and go to **Site Management** > **Customer Edge** > **Secure Mesh Sites v2**
- Click **Add Secure Mesh Site**
- Create a smsv2 site using the following details:
  - Name: **studentx-aws-smsv2**
  - Provider: **AWS**
  - High Availability: **Disable**
  - Leave all other settings as default
- Click **Add Secure Mesh Site**

########################################################################################################

**2. Provision AWS resources for the SMSv2 CE site**    
+ In the AWS Management Console, implement the following infrastructure:
    - Create a new VPC (or use an existing one) with at least two subnets in the same availability zone
    - The two subnets can be named as follows:
        - studentx-slo (public subnet)
        - studentx-sli (private subnet)
    - Create a route table for each subnet and associate it with the subnets respectively
    - Create an internet gateway and attach it to the VPC
    - For the public subnet (studentx-slo), add a route to the internet gateway
    - Create a Security Group with all required ports open for the SMSv2 CE site (e.g., TCP 443, UDP 4500, UDP 500)
    - Create an SSH Key Pair to use for accessing the SMSv2 CE site instance
    - Allocate an Elastic IP address to associate with the SMSv2 CE site


# Infrastructure Diagram                    
    VPC               Subnets         Route Tables         Network Connections 
                    
                    studentx-slo    studentx-slo-rt
    studentx-vpc                                            studentx-igw
                    studentx-sli    studentx-sli-rt  

###########################################################################################################

**3. Generate the Node token for the SMSv2 CE site in F5 Distributed Cloud**
- In the F5 Distributed Cloud Console, navigate to **Multi-Cloud Network Connect** > **Site Management** > **Secure Mesh Sites v2**
- Click on the "Action" icon next to the name of the SMSv2 CE site you created (studentx-aws-smsv2 for example) and select "Generate Node Token"
- In the Generate Node Token page, click "Copy cloud-init" to copy the cloud-init script to your clipboard and save it to your preferred Text Editor for later use during the instance deployment in AWS


###########################################################################################################

**4. Deploy the SMSv2 CE site in AWS**
- In the AWS Management Console, navigate to **EC2 > Instances** and click **Launch Instance**
- Configure the instance with the following details:
    - Name: **studentx-aws-smsv2**
    - Application and OS Images: Select the F5 Distributed Cloud SMSv2 CE site AMI for your region
        - Click on **Browse more AMIs** and search for **F5 Distributed Cloud byol** to find the correct AMI
        - Click the **AWS Marketplace AMIs** tab
        - On the search results, find the F5 Distributed Cloud Customer Edge (BYOL) AMI and click "Select"
    - Instance Type: Select **m5.2xlarge** or larger instance type based on your requirements
    - Key Pair: Select the SSH Key Pair you created for the CE site
    - Network Settings:
        - Network: Select the VPC you created for the CE site (studentx-vpc)
        - Subnet: Select the public subnet you created for the CE site (studentx-slo)
        - Auto-assign Public IP: Disable (since you will be using the Elastic IP address you allocated and associated with the ENI)
        - Firewall (security group): Click the **Select existing security group** option and select the Security Group you created for the CE site
           - Select the **Common security groups** drop-down and choose the Security Group you created for the CE site 
    - Expand **Advanced Network Configuration** and on Network Interface 1, ensure **New interface** is selected
    - Click **Add network interface** to add a second network interface. This will serve as the private interface for the SMSv2 CE site to connect to the internal/private subnet
        - For Network Interface 2,
            - Network interface: Select "New interface"
            - Subnet: Select the private subnet you created for the CE site (studentx-sli for example)
        - Auto-assign Public IP: Disable
        - Firewall (security group): Select the "Select existing security group"
           - Select the **Common security groups** drop-down and choose the Security Group you created for the CE site

    - Configure storage: Enter **80** GB 
    - Advanced Details: In the **User data** field, paste the cloud-init script you copied from the F5 Distributed Cloud Console in step 3
    - Click **Launch** to launch the instance


**5. Allocate and Associate an Elastic IP address to SMSv2 CE site public interface**
    - In the AWS Management Console, navigate to **EC2 > Instances** and select the checkbox next to your newly created CE instance
    - Go to the Networking tab and expand Network Interfaces and check which of the ENI IDs is mapped to the public interface (Network Interface 0) of the instance (e.g., eni-xxxxxxxxxxxx)
        - You can identify the ENI mapping by checking the subnet ID to verify if it matches the public subnet you selected during the instance deployment (studentx-slo for example)
    - Once you have identified the ENI that is mapped to the public interface, navigate to **EC2 > Network Interfaces** and select the checkbox next to that ENI (e.g., eni-xxxxxxxxxxxxxxxxxxxx)
    - Click on the **Actions** button and select **Associate Elastic IP Address**
    - Under Association details, click the Elastic IP address drop-down and select the Elastic IP address you allocated for the CE site in step 2 
    - Click **Associate** to associate the Elastic IP address with the ENI and complete the Elastic IP association process

**6. Verify the SMSv2 CE site deployment in F5 Distributed Cloud Console**
    - After the instance is rebooted in AWS, go back to the F5 Distributed Cloud Console and navigate to **Multi-Cloud Network Connect** > **Site Management** > **Secure Mesh Sites v2**
    - The **Site Admin State** should show as **Provisioning**" while the CE site is being deployed and provisioned in AWS. Once the deployment is complete, the Site Admin State should change to **Online**, indicating that the SMSv2 CE site is      successfully deployed and connected to F5 Distributed Cloud. You can also click on the site name (studentx-aws-smsv2 for example) to view more details about the site, including the node status and network interfaces.    

**Congratulations!** You have successfully deployed an F5 Distributed Cloud Secure Mesh Site v2 in AWS using ClickOps. You can now proceed to configure the site and establish network connections as needed.
