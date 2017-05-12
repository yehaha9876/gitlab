// import UsersSelect from '../users_select';
import UsersSelect from '../users_select';

const Dispatcher = {
  init(page) {
    switch (page) {
      case 'projects:edit':
        // eslint-disable-next-line no-new
        new UsersSelect();
        break;
      default:
        break;
    }
  },
};

export default Dispatcher;
