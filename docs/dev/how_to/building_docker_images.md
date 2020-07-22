# Building Docker Images

## Using [Dobi](https://dnephin.github.io/dobi/)

If you are unfamiliar with Dobi, it is a build automation tool for Docker applications. You can check out a lot of what Dobi has to offer at the link above or [here](https://github.com/dnephin/dobi).

### Local Development

Uncomment the `.envrc` file and run `direnv reload`. Dobi will use those env variables through variable substitution when you want to build the docker images locally. If you are already using `direnv` you can just add those env variables to what you are using or just export the env variables locally. 

You can then run the specified task (if there are any) that you would like Dobi to do. Since there are not many build steps there is no need to specify robust tasks for Dobi here. All that is needed is simply to run `dobi chef` after exporting those env variables and Dobi will build, tag and push your image to your image registry.