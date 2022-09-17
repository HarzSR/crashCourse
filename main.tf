provider "aws" {
    profile = "awsplaypen"
    region = "ap-southeast-2"
}

resource "aws_instance" "harz_learn_terra" {
    ami = "ami-0b55fc9b052b03618"
    instance_type = "t2.micro"

    tags = {
        Name = "harzIlu"
        Key = "None"
    }
}