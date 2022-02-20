# Helmchart for Amplify API-Management


## Create Admin-Users

If the API management platform is run in a container platform, then you need to configure the admin users either via an externally provided file: apigateway/conf/adminUsers.json 
or via an [LDAP connection](https://docs.axway.com/bundle/axway-open-docs/page/docs/apim_administration/apigtw_admin/general_rbac_ad_ldap/index.html) which is the preferred way.  

User management in API Gateway Manager is disabled because changes to the file: `adminUsers.json` are not persisted.  

If you do not want to set up an LDAP connection, then you can either include the file directly in the admin node manager image via merge directory or provide it via a 
mounted secret. The latter option is certainly more flexible, since you do not have to rebuild the image for each user.  

The following steps are necessary to set up a secret mount based on the helmet chart.  

1. Create the secret based on the `adminUsers.json`
```
wget -o adminUsers.json https://raw.githubusercontent.com/Axway/Cloud-Automation/master/APIM/Helmchart/examples/general/adminUsers.json
kubectl create secret generic axway-apigateway-admin-users -n apim --save-config --dry-run=client --from-file=adminUsers.json=adminUsers.json -o yaml | kubectl apply -f -
```
