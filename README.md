# remove-inactive-mmonit
Removes hosts marked as 'Inactive' in M/Monit.

if you have M/Monit 3.5 or newer you can use the following api call instead:

`curl -b ~/.mmonit/cookie -d "inactive=86400" http://127.0.0.1:8080/admin/hosts/delete`
