import { highlightFeatures } from './feature_highlight';
import bp from '../breakpoints';

export const highlightOrder = ['issue-boards'];

export function initHighlightOrder(order) {
  if (bp.getBreakpointSize() === 'lg') {
    highlightFeatures(order);
  }
}
