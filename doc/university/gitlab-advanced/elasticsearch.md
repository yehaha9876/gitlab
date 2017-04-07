# Elasticsearch

This document covers additional configuration options to integrate Elasticsearch 
with GitLab.

More detailed information of what this feature is and it's options is available 
at the [Elasticsearch Integration](https://docs.gitlab.com/ee/integration/elasticsearch.html#elasticsearch-integration) 
doc.

***

## Elasticsearch Docker Container

For this setup we want to have GitLab as a container and Elasticsearch as another 
container both communicating through a Docker network. This example is running 
on an EC2 instance so we'll be seeing some specific AWS values as part of the 
code blocks but also notice that this setup does require at least 8GB of RAM.
   
Update the host machine:

```
sudo apt-get update
```

Install and test Docker

```
wget -qO- https://get.docker.com/ | sh
sudo docker run hello-world
```
Now we can create the network where `gitlab` stands for the network name. 

```
    sudo docker network create gitlab_network
```

Get GitLab's Docker image and start a container. In this code block we are using
 the public DNS as both the hostname and the `external_url` value which means it
 will be accessible through this value in your browser. 

The publish options are exposing the ports but notice that I'm changing the SSH 
 port as it collides with the host's SSH. We can also change the volumes where 
 we want our configuration, data and home directory to be stored. 
 
An important option to note is `--detach` which will run the container in the 
background and configure GitLab when it first starts up. I like having a session 
open for logs so I usually change that for `-it` to view the output of the 
 configuration. 

```
sudo docker run --detach \
   --hostname ec2-52-15-116-57.us-east-2.compute.amazonaws.com \
   --env GITLAB_OMNIBUS_CONFIG="external_url 'http://ec2-52-15-116-57.us-east-2.compute.amazonaws.com';" \
   --publish 443:443 \
   --publish 80:80 \
   --publish 2289:22 \
   --name gitlab \
   --restart always \   
   --volume /srv/gitlab/config:/etc/gitlab \
   --volume /srv/gitlab/logs:/var/log/gitlab \
   --volume /srv/gitlab/data:/var/opt/gitlab \
   --network gitlab_network \
   gitlab/gitlab-ee:latest
```

Let's turn to Elasticsearch now. For GitLab prior to version 9.0 we need
Elasticsearch version 2.4 and from 9.0 upwards we need version 5.1. Also notice 
that version 2.4 requires manually installing the `delete-by-query` plugin.
 
Download the Elasticsearch image and start a container. We're also connecting it 
to our `gitlab` network. If installing a different version you should change the
number at the end of the command.

```
sudo docker run -d --name elasticsearch --network gitlab_network elasticsearch:5.1
```

If you went with the 2.4 version you can login in to the container and install 
the plugin with:

```
sudo docker exec -it elasticsearch /bin/bash
bin/plugin install delete-by-query
exit
```

You can now confirm the Elasticsearch is reachable by loging into the `gitlab` 
container and trying to access it.

```
sudo docker exec -it gitlab /bin/bash
curl http://elasticsearch.gitlab:9200
exit
```

From the admin UI you'll need to activate Elasticsearch by going to the Settings 
screen which you'll find under the gear icon's drop down menu. 

Closer to the bottom there is an Elasticsearch section with two checkboxes that 
you'll need to click on:  `Elasticsearch indexing` and 
`Search with Elasticsearch enabled`. Finally add the url we tested through the 
container `http://elasticsearch.gitlab:9200`. Don't forget to save the changes.

The final part of this configuration is to create the indexes on the `gitlab`
 container. We'll just index everything but if you have a larger instance please 
 go through the indexing procedure from the docs. 

```
sudo docker exec -it gitlab /bin/bash
gitlab-rake gitlab:elastic:create_empty_index
gitlab-rake gitlab:elastic:index_repositories
exit
```

Done! Go into your instance and try searching for a code pattern. You will now 
see the code and merge request categories.  

If you would like to version control your Docker images make sure to commit the 
 changes.
 
```
docker commit <container-id>  <username>/<image-name>:<version>
```

***

## AWS Elasticsearch Service
 
This setup uses the AWS Elasticsearch cluster service. This is not a best 
practice guide, it's more of a getting started or proof of concept so please 
make sure to review the final setup and change it to meet your team's 
requirements. 

The first step here is dealing with the Access Policy. I have created an IAM user
 and attached a policy to it. You can also use your own user to test this out. 
 
At the IAM screen choose Policies -> Create Policy -> Create your own policy. 
I'll leave this one open but make sure to scope it better afterwords.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "es:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
```

After saving this you can choose Users on the left panel and select the one that 
we'll be using for this. Click on Add Permissions and then Attach existing 
policies directly. Look for the recently saved policy and select it.

Before moving out of the IAM screen we'll need to get a few more details. Look 
 for the user again and copy the `User ARN` from it's profile screen. Now click 
 on the security credentials tab and press the Create access key button. Make 
 sure to copy the Access and Secret access key. We'll be using this info 
 shortly.
 
Now we can start creating an Elasticsearch cluster. Navigate to the 
Elasticsearch service. The name is unimportant just make sure to choose the 5.1 
Elasticsearch version. Note that AWS does not offer a 2.3 version. I would also 
suggest at least a medium sized instance for the cluster node type. Now for the 
policy choose from the dropdown menu the `Allow or deny access to one or more 
AWS accounts or IAM users`. On the pop up screen choose to allow and paste the 
User's ARN in the text field. now save and confirm.
  
It takes a while but when the cluster is finally ready make sure to copy the 
Endpoint value. 

Now let's create the indexes on the `gitlab` instance. We'll just index 
everything but if you have a larger instance please go through the indexing 
procedure from the docs. SSH into your GitLab server and run the following 
commands:

```
sudo gitlab-rake gitlab:elastic:create_empty_index
sudo gitlab-rake gitlab:elastic:index_repositories
sudo gitlab-rake gitlab:elastic:index_database
```

The final part of this configuration is done through the admin UI. You'll need 
to activate Elasticsearch by going to the Settings screen which you'll find 
under the gear icon's drop down menu.
 
Closer to the bottom there is an Elasticsearch section with two checkboxes that 
you'll need to click on:  `Elasticsearch indexing` and 
`Search with Elasticsearch enabled`. For the url paste the Endpoint value from 
the cluster we created but be sure to prepend `https://`. Now on the section 
below we need to add specific AWS values. First check the 
`Using AWS hosted Elasticsearch with IAM credentials` checkbox. For the region 
you can find that as part of the Endpoint's url or just find it in the AWS web 
console. Now the `AWS Access Key` and `AWS Secret Access Key` are the two values 
we copied from the IAM user profile under the security credentials tab. 
Don't forget to save the changes.

Done! Go into your instance and try searching for a code pattern. You will now 
see the code and merge request categories.