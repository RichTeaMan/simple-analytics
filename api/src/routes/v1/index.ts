import { Router } from 'express';

import books from './books.route';
import events from './events.route';

const router = Router();

router.use('/books', books);

router.use('/events', events);

export default router;

