import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

const main = pulumi.output(aws.getCallerIdentity({ async: true }));
export const accountID = main.accountId

const nixArm2003 = pulumi.output(accountID.apply(accountID => aws.getAmi({
  filters: [{
    name: "name",
    values: ["NixOS-20.03beta-81915.gfedcba-aarch64-linux"],
  }],
  owners: [accountID], // This owner ID is Amazon
  mostRecent: true,
})));

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

const server = new aws.ec2.Instance("remote-builder1", {
  // @ts-ignore - a real instance type I swear!
  instanceType: "a1.metal",
  securityGroups: [group.name], // reference the security group resource above
  ami: nixArm2003.id,
  rootBlockDevice: {
    volumeSize: 256
  },
  keyName: "fruit_fig2"
});

export const instanceID = server.id

const localNixpkgs = "$HOME/localnix/local-nixpkgs"

// Build the pi4 kernel with KVM enabld
// Breaking down the command a bit:
// -j0 means no local workers. We want to make sure to do this all on the server
// the builders arg is explained here: https://nixos.org/nix/manual/#chap-distributed-builds
export const nixBuildPi4KVM = server.publicIp.apply((publicIP: string) => `\
nix-build -j0 '<nixpkgs/nixos>' \
  -A system \
  -I nixos-config=../pi4_kvm.nix \
  -I nixpkgs=${localNixpkgs} \
  -I nixpkgs-overlays=../overlays/rpi4 \
  --argstr system aarch64-linux \
  --builders 'ssh://root@${publicIP} aarch64-linux - 16 2 kvm,nixos-test,benchmark,big-parallel'
`)

const region = pulumi.runtime.getConfig("aws:region")!
const stopAction = accountID.apply(accountID => `arn:aws:swf:${region}:${accountID}:action/actions/AWS_EC2.InstanceId.Terminate/1.0`)

const minute = 60
const period = 2 * minute

const metricAlarm = new aws.cloudwatch.MetricAlarm("sleepingBuilder", {
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