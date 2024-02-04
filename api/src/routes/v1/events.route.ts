import { Request, Response, Router } from 'express';
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { v4 as uuidv4 } from 'uuid';

const router = Router();

const IP_HEADERS = ['x-forwarded-for'];
const BUCKET_NAME = "richteaman-simple-analytics-events";

router.get('/', async (req: Request, res: Response) => {
  try {

    let ip = "unknown";
    for (const ipHeader of IP_HEADERS) {
      const value = req.headers[ipHeader];
      if (value) {
        ip = `${value}`;
      }
    }

    const client = new S3Client({ region: "eu-west-2" });
    await client.send(new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: uuidv4(),
      Body: JSON.stringify({
        ip,
        datetime: new Date()
      })
    }));

    res.status(201);
  } catch (error) {
    console.error('An error ocurred:', error);
    res.status(500).json(error);
  }
});

export default router;
