resource "google_service_account" "gcs_storage" {
  account_id   = "gcs-storage"
  display_name = "GCS Storage Access"
}

resource "google_project_iam_member" "gcs_sa_storage_admin" {
  project = "ordinal-reason-457811-u0"
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.gcs_storage.email}"
}

resource "google_storage_bucket" "app_storage_bucket" {
  name                        = "my-app-storage-avl-5482671"
  location                    = "EU"
  force_destroy               = true
  uniform_bucket_level_access = true
}
