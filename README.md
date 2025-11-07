# GCP Modular Infrastructure Setup

This repository provides a reusable, fully automated GCP setup using Terraform and Cloud Build.
It separates the **Bootstrap Project** (infrastructure and CI/CD setup) from **Application Projects** (created automatically per app).

---

## 📁 Structure

```
config.env
bootstrap-infra/
  ├── main.tf
  ├── variables.tf
  ├── outputs.tf
  └── scripts/setup_bootstrap.sh
app-repo-template/
  ├── infra/
  │   ├── main.tf
  │   └── variables.tf
  ├── cloudbuild.yaml
  ├── app/main.py
  └── tests/test_app.py
```

---

## ⚙️ Step-by-step Usage

### 1️⃣ Configure variables
Edit `config.env` to set:
```
BOOTSTRAP_PROJECT_ID="your-bootstrap-project-id"
ORG_ID="your-org-id-or-blank"
REGION="us-central1"
BILLING_ACCOUNT_ID="your-billing-account-id"
GITHUB_OWNER="your-github-user-or-org"
GITHUB_REPO_NAME="your-app-repo-name"
GITHUB_INSTALLATION_ID="your-github-app-installation-id"
GITHUB_TOKEN_SECRET_NAME="github-token-secret"
```

### 2️⃣ Run Bootstrap Setup (manual, once)
```
cd bootstrap-infra/scripts
bash setup_bootstrap.sh
```
This enables required APIs and creates your Terraform state bucket.

You can then run Terraform:
```
cd ..
terraform init
terraform apply
```
This provisions the bootstrap infra, GitHub connection, and Cloud Build trigger.

---

### 3️⃣ Deploy an App (automated)
- Push your app repo (based on `app-repo-template/`) to GitHub.
- The Cloud Build trigger (in the bootstrap project) runs automatically.
- It:
  1. Impersonates the Terraform Admin SA.
  2. Runs Terraform to create the app’s GCP project and resources.
  3. Builds & pushes Docker image.
  4. Deploys to Cloud Run.

---

### 4️⃣ Modify & Extend
You can:
- Add new Terraform modules in `app-repo-template/infra/` to provision any GCP resource.
- Add pytest unit tests in `tests/`.
- Extend Cloud Build YAML with build/test stages.

---

## ✅ Security Highlights
- **No hardcoded credentials** — uses Cloud Build impersonation.
- **No local secrets** — GitHub PAT stored in Secret Manager.
- **Fully auditable** — IAM and Cloud Audit Logs track all actions.

---

### 🧩 Future Improvements
- Add org-level Terraform for Terraform Admin SA & roles.
- Parameterize triggers for multiple app repos.

---

Made for: Scalable, modular, production-grade GCP CI/CD pipelines 🚀
