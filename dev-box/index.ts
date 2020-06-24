import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

const main = pulumi.output(aws.getCallerIdentity({ async: true }));
export const accountID = main.accountId

const group = new aws.ec2.SecurityGroup("remoteBuilder-allowSSH", {
  ingress: [
    { protocol: "tcp", fromPort: 22, toPort: 22, cidrBlocks: ["0.0.0.0/0"] },
  ],
  egress: [
    { protocol: "tcp", fromPort: 0, toPort: 65535, cidrBlocks: ["0.0.0.0/0"] },
    { protocol: "udp", fromPort: 0, toPort: 65535, cidrBlocks: ["0.0.0.0/0"] },
    { protocol: "icmp", fromPort: -1, toPort: -1, cidrBlocks: ["0.0.0.0/0"] }
  ]
});

const server = new aws.ec2.SpotInstanceRequest("dev-box", {
  instanceType: "r5a.4xlarge",
  securityGroups: [group.name], // reference the security group resource above
  ami: "ami-06562f78dca68eda2", // NixOS 20.03
  rootBlockDevice: {
    volumeSize: 64 // TODO make this smaller
  },
  keyName: "fruit_fig2"
})

export const instanceID = server.id
export const serverIP = server.publicIp

const region = pulumi.runtime.getConfig("aws:region")!
const stopAction = accountID.apply(accountID => `arn:aws:swf:${region}:${accountID}:action/actions/AWS_EC2.InstanceId.Terminate/1.0`)

const minute = 60
const period = 2 * minute

const metricAlarm = new aws.cloudwatch.MetricAlarm("sleepingDevBox", {
  comparisonOperator: "LessThanOrEqualToThreshold",
  evaluationPeriods: 60 * minute / period,
  metricName: "CPUUtilization",
  alarmActions: [stopAction],
  dimensions: {
    InstanceId: server.id,
  },
  namespace: "AWS/EC2",
  period,
  statistic: "Average",
  threshold: 20,
  alarmDescription: "If the worker isn't doing anything, bring it down."
});