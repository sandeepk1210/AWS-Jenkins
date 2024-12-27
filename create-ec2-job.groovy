job('create-ec2-job') {
    description('This job will create an EC2 instance in AWS using the Job DSL plugin.')

    // You can customize the parameters below as needed
    steps {
        shell("""
            echo "Fetching the latest AMI ID..."
            AMI_ID=\$(aws ec2 describe-images \\
                --owners amazon \\
                --filters 'Name=platform,Values=Linux' 'Name=state,Values=available' \\
                --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \\
                --output text)
            
            echo "AMI ID: \$AMI_ID"
            
            echo "Fetching an existing security group ID..."
            SECURITY_GROUP_ID=\$(aws ec2 describe-security-groups \\
                --filters 'Name=group-name,Values=default' \\
                --query 'SecurityGroups[0].GroupId' \\
                --output text)
            
            echo "Security Group ID: \$SECURITY_GROUP_ID"
            
            echo "Fetching the subnet ID..."
            SUBNET_ID=\$(aws ec2 describe-subnets \\
                --filters 'Name=availability-zone,Values=us-east-1a' \\
                --query 'Subnets[0].SubnetId' \\
                --output text)
            
            echo "Subnet ID: \$SUBNET_ID"
            
            echo "Creating EC2 Instance..."
            aws ec2 run-instances \\
                --image-id \$AMI_ID \\
                --instance-type t2.micro \\
                --key-name my-key-pair \\
                --security-group-ids \$SECURITY_GROUP_ID \\
                --subnet-id \$SUBNET_ID \\
                --region us-east-1  # Your AWS region
        """)
    }
}
