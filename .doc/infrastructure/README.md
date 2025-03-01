# Infrastructure

## Getting started

```bash
brew install terraform
```

```bash
 terraform apply -var-file=shared.tfvars -var-file=staging.tfvars
 ```

 You will need to have your domain registar use the Google Cloud DNS nameservers. After applying the Terraform config, you can go to the Google Cloud Console under Networks services > Cloud DNS. Find your domain name and get the DNS nameservers. Go to your domain registar and use all of the DNS nameservers (under the NS record like ns-cloud-b1.googledomains.com.).

```
<!-- For interacting with kubectl commandline -->

gcloud container clusters get-credentials hostr-staging-gke --region us-central1-a
```

```
gcloud secrets create nsec \
    --replication-policy="automatic" && 
    echo "yournsec" | gcloud secrets versions add nsec --data-file=-
```
