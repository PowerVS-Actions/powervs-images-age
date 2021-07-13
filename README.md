# powervs-vms-age
Get the age of VMs running in PowerVS

```
add the necessary data in the cloud_accounts:
    cloud_account_number:cloud_account_name,api_key

chmod +x ./images.sh; images.sh

mv ./all_images_DATE.csv ./all.csv

docker run --rm -v $(pwd)/all.csv:/python/all.csv -v $(pwd)/database.ini:/python/database.ini images:latest
```
