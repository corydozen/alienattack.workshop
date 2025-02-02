import { Construct } from '@aws-cdk/core';
import { ResourceAwareConstruct, IParameterAwareProps } from './../resourceawarestack'
import { CloudFrontWebDistribution, CfnCloudFrontOriginAccessIdentity } from '@aws-cdk/aws-cloudfront';
import { Bucket, BucketPolicy} from '@aws-cdk/aws-s3';
import { PolicyStatement, ArnPrincipal } from '@aws-cdk/aws-iam';


export class ContentDeliveryLayer extends ResourceAwareConstruct {

    constructor(parent: Construct, name: string, props: IParameterAwareProps) {
        super(parent, name, props);
        this.createDistribution(props);
    }

    private createDistribution(props: IParameterAwareProps) {

        let s3BucketOrCnfBucket = props.getParameter('appBucket');
        let appBucket = <Bucket> Bucket.fromBucketName(this, props.getApplicationName()+'ImportedBucket', s3BucketOrCnfBucket.bucketName);
        
        let cloudFrontAccessIdentity = new CfnCloudFrontOriginAccessIdentity(this,this.properties.getApplicationName()+'CDNAccessId', {
            cloudFrontOriginAccessIdentityConfig : {
                // This is the name of the identity
                comment : this.properties.getApplicationName()+'CDNAccessId'
            }
        })

        let bucketPolicy = new BucketPolicy(this, this.properties.getApplicationName()+"AppBucketPolicy", {
            bucket : appBucket
        });
        
        bucketPolicy.document.addStatements(
            new PolicyStatement({
                resources : [  appBucket.bucketArn+'/*' ],
                actions : [ 's3:GetObject' ],
                principals : [
                    new ArnPrincipal('arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity '+cloudFrontAccessIdentity.ref) //cloudFrontAccessIdentity.cloudFrontOriginAccessIdentityConfig)
                ]
            })
        );

        let distribution = new CloudFrontWebDistribution(this, props.getApplicationName(), {
            originConfigs: [
                {
                    s3OriginSource: {
                         s3BucketSource: appBucket,
                         originAccessIdentityId : cloudFrontAccessIdentity.ref
                    },
                    behaviors : [ {isDefaultBehavior: true}]
                }
            ]
         });

         this.addResource("cdndomain",distribution.domainName);
    }
}