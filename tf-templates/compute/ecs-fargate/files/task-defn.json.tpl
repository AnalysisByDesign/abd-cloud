[
  {
    "name": "${container_name}",
    "image": "${docker_image}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${container_port},
        "protocol": "tcp"
      }
    ],
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "${awslogs-group}",
      "awslogs-region": "${awslogs-region}",
      "awslogs-stream-prefix": "${awslogs-stream-prefix}"
      }
    }
  }
]
