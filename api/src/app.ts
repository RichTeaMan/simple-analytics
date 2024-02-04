import express from 'express';
import serverless from 'serverless-http';

import routes from './routes';

console.log("hello world");

const app = express();

console.log("still kicking");

app.use(express.json());

console.log("a");

app.use('/', routes);

console.log("b");

app.use((req: express.Request, res: express.Response, next: express.NextFunction) => {
  res.status(404).send();
});

console.log("c");

app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  res.status(err.status || 500).send();
});

console.log("d");

export const handler = serverless(app);

console.log("e");
