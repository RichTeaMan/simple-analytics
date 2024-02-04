import { Request, Response, Router } from 'express';

import v1 from './v1';

const router = Router();

router.use('/v1', v1);

router.get('/', async (req: Request, res: Response) => {
    try {
        res.status(200).json(["root"]);
    } catch (error) {
        console.error('An error ocurred:', error);
        res.status(500).json(error);
    }
});

export default router;
