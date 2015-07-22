# CloudWatch Logs Agent #

The container contains CloudWatch Logs Agent for logging into Amazon CloudWatch. The agent is started only if the container
is launched in Amazon EC2 environment.

To utilize the CloudWatch Logs Agent the derived containers must contain a configuration file *config/aws/awslogs.conf*.
The configuration file cannot contain *[general]* section as it is appended to the end of existing configuration in the
container. This container supports *{server_name}* predefined variable that is replaced by the content of $SERVER_NAME environment variable.
All configuration options are described in [CloudWatch Logs Agent Reference](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/AgentReference.html).

Your configuration file then has to be registered in the *Dockerfile* of your derived container:

    ADD config/aws/awslogs.conf /tmp/
    RUN awslogs-add-config.sh /tmp/awslogs.conf

To use CloudWatch Logs Agent in containers not derived from *apollo13/ubuntu* construct the *Dockerfile* to execute the
code snippet from Step 19 of [Quick Start: Install and Configure the CloudWatch Logs Agent on a New EC2 Instance](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/EC2NewInstanceCWL.html).
