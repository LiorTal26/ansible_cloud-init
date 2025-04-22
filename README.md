# Ansible Cloud-Init Project

This project provides an Ansible playbook to configure AWS instances using Cloud-Init. It ensures the necessary AWS CLI tools are installed and configured, creates the required Cloud-Init configuration files, and deploys the `cloud-init-update-dns-aws.sh` script to the target instance.

## Features
- Runs an Ansible playbook with Cloud-Init.
- Creates the `/var/lib/cloud/seed/nocloud` directory on the target instance.
- Generates `user-data` and `meta-data` files in the above directory.
- Uses the `user-data` file to define the Cloud-Init configuration, including running the `cloud-init-update-dns-aws.sh` script on boot to update the AWS instance DNS.
- Verifies AWS CLI is installed and configured on the AWS instance.
- Allows customization via `vars/main.yml` and inventory files.

## Setup Instructions

1. **Update Variables**  
    Modify the `vars/main.yml` file to include your specific configuration values.

2. **Update Inventory**  
    Edit your inventory file to include the target AWS instance details.

3. **Run the Playbook**  
    Execute the Ansible playbook to configure the AWS instance:
    ```bash
    ansible-playbook -i inventory playbook.yml
    ```

## Prerequisites
- Ensure AWS CLI is installed and configured on the target instance.
- Verify that the `cloud-init-update-dns-aws.sh` script is present in the project directory.

## Cloud-Init Configuration
The playbook creates the `/var/lib/cloud/seed/nocloud` directory on the target instance and generates the following files:
- **`user-data`**: Contains the Cloud-Init configuration. You can refer to the `user-data` file in this project for syntax and customization.
- **`meta-data`**: Provides metadata required by Cloud-Init.

The `user-data` file is configured to run the `cloud-init-update-dns-aws.sh` script during the instance boot process to update the AWS instance DNS.

## Notes
- Ensure your AWS credentials are properly configured before running the playbook.
- Test the playbook in a staging environment before deploying to production.
- The `cloud-init-update-dns-aws.sh` script will be automatically copied to the AWS instance as part of the playbook execution.

