docker cp ${PWD}/terraform opt_gitlab-runner_1:/bin
gitlab_url=http://gitlab
gitlab_token=$1
docker exec -i opt_gitlab-runner_1 gitlab-runner register -n --url ${gitlab_url} --name "gitlab-runner" --registration-token ${gitlab_token} --executor shell
docker exec -it --user gitlab-runner opt_gitlab-runner_1 ssh-keygen -t rsa -N "" -f /home/gitlab-runner/.ssh/id_rsa
docker exec -it --user gitlab-runner opt_gitlab-runner_1 cat /home/gitlab-runner/.ssh/id_rsa.pub
