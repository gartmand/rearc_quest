# Initial Setup and Brainstorming
First, I considered what to do for a CI/CD workflow. I tried to treat this as a real application, so I wanted to make sure I gamed out a build and deployment process. 

For Infrastructure-as-Code, I knew I wanted to incorporate Terraform, since I have experience with it, and it was the preferred option in the quest.

For builds, at first I considered using CodeConnections and then using CodeBuild to perform specific actions (build, apply TF, etc.) based on the event data coming from GitHub. 

Due to the relatively small size of the app, I placed both the app and infrastructure code into one repo. This led me to look at the convenience of using GitHub Actions via OIDC. This would allow me to specify environments in GitHub and control the build and deployment actions that way. In a real setup, I would definitely break out the infra into its own repo and/or further modularize it; it would be especially useful as a pattern for multiple applications.

I selected GitHub Actions due to these factors, and also because I was less than enthused about incorporating the CodeBuild spec into my Terraform IaC, which would mean TF state changes if I needed to update the build. I also have less exposure to GitHub Actions, so I thought it would be a good learning experience.

The first portion of functionality I had to tackle was creating a global OIDC provider for GitHub Actions within AWS. This would allow me to look up the provider across multiple environments if I wanted to create those. I scaffolded a Production and Development environment. The Production environment was to be the MVP. I originally considered that the Development environment might just be one deployed application, but decided allowing multiple feature branches to have their own deployed containers would be more interesting (and useful in a real developer platform). An optional staging environment was considered, but that was so similar to the Production environment that I decided to skip it for now. Production would be reserved for a tagged release process (promotion). I decided here that I would use the GitHub Releases process for this, since it incorporates with Actions very easily.

My Terraform uses us-east-1 for everything currently; I omitted DR capabilities for the sake of both cost and brevity.

The very first bit of Terraform that I needed to apply was to bootstrap the global OIDC provider. Applying this is "one and done". 
1. I created an S3 bucket to store my Terraform state, and enabled bucket versioning.
2. I passed the bucket in for the backend when running terraform init.
3. I grabbed the appropriate OIDC config from the GitHub / AWS guides, made an OIDC provider resource block, and applied it.

I made a TF module that creates an IAM role that can be assumed by a specified repo and environment coming in via a specified OIDC provider.

Then, for my Production environment, I invoked the module using the GH Actions OIDC provider ARN, production, and my repo, along with the local environment name (production of course).
I did an initial apply just to verify the role creation.

# Dockerizing the Application
Once that was done, I had a solid foundation on which I could start adding necessary permissions via IAM Polices. I didn't want to spend too much time up front on adding all the permissions, since I needed to decide on and implement a container hosting solution. For an MVP I could still run the Terraform applies locally, and I wanted to hit the MVP. I hadn't decided on how to flesh out least privilege for the GitHub Actions OIDC provider (bootstrapping roles and policies so this role wouldn't need excessive permissions, i.e.). So, I set that part aside for now.

The critical first step to deploying was to Dockerize the application. I wrote the Dockerfile after a little refresher on setting up a node application, then ensured it wasn't running as root and locked down the permissions on the files. Then, I built and spun up the image locally, checking the /docker endpoint to verify, as well as exec'ing into the running container to make sure I was satisfied with the structure and permissions.

The next step in order to use ECS was to set up my ECR repository, which I bootstrapped (another "one and done") with Terraform.

I tagged and pushed the image to ECR directly from my PC, using the tag "latest" to start out.

# Deploying to ECS
Next, for the hosting - I could have used ECS with Fargate and configured an ALB separately within the Terraform, or gone really complex and used EKS; however, I decided that due to the simplicity of the application, I would use AWS ECS Express Mode. I decided for cost and simplicity sake to share a cluster between workloads, which should happen automatically unless I specify separate clusters. 

When I initially tried to deploy in Express Mode (I haven't done so before), I used recommended Amazon-defined roles for the task definition and infra roles on the service. This led to a few Access Denied errors. I researched in CloudTrail, located the failures, and attached additional permissions to the infrastructure role used by the ECS Express Mode gateway service as needed. Amazon Q was able to suggest a decent managed policy to cover gaps here. 

Once I applied again and forced an ECS service redeployment (for MVP I was reusing the "latest" tag), the service came up. The lovely thing with Express Mode is that AWS handled creating a Load Balancer and a TLS cert, along with providing a .on.aws URL. I navigated there and grabbed the passphrase from my application root, then created a Secret in AWS Secrets Manager from it. Then, I added permission to the ECS Task Execution Role to get the secret. I then passed the secret in on the Express Mode service resource using valueFrom to pull it by ARN. Once I applied this change, production was at MVP.

Up to the point of MVP, use of GenAI was primarily in researching specific syntaxes, and Terraform was written primarily by modifying boilerplate from documentation and examples. I purposely avoided generating the codebase via prompt, primarily because of the challenge.

# What's next?
Given enough time, to make this a more production-ready solution, I would:
* Implement the complete CI/CD pipeline within GitHub Actions to build, push, and deploy the application - including using tags / GitHub releases
    * I implemented the OIDC connections up front, which in hindsight was overkill for MVP and wasted time
* Create custom IAM policies for the ECS Task Execution role and ECS Infrastructure role; the managed policies are too broadly scoped for least privilege
* Use ECS with Fargate or EKS to allow for more fine-grained control over the deployment process, load balancing, security groups, and TLS termination
    * ECS Express Mode only allows blue/green rollouts
    * It also only allows for one primary container, so sidecar patterns are not supported
    * Several other disadvantages for production-grade applications, mostly relating to flexibility
* Use ACM for certificate management
* Implement the ability to deploy feature branches to development preview environments
* Create separate ECS Clusters for each environment to isolate the workloads
* Refactor the "modules" I have, particularly ecs-express-gateway, to be less coupled