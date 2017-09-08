import { initHighlightOrder } from '~/feature_highlight/feature_highlight_options';
import bp from '~/breakpoints';

describe('feature highlight options', () => {
  describe('initHighlightOrder', () => {
    const highlightOrder = [];

    beforeEach(() => {
      // Check for when highlightFeatures is called
      spyOn(highlightOrder, 'find').and.callFake(() => {});
    });

    it('should not call highlightFeatures when breakpoint is xs', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('xs');

      initHighlightOrder(highlightOrder);
      expect(bp.getBreakpointSize).toHaveBeenCalled();
      expect(highlightOrder.find).not.toHaveBeenCalled();
    });

    it('should not call highlightFeatures when breakpoint is sm', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('sm');

      initHighlightOrder(highlightOrder);
      expect(bp.getBreakpointSize).toHaveBeenCalled();
      expect(highlightOrder.find).not.toHaveBeenCalled();
    });

    it('should not call highlightFeatures when breakpoint is md', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('md');

      initHighlightOrder(highlightOrder);
      expect(bp.getBreakpointSize).toHaveBeenCalled();
      expect(highlightOrder.find).not.toHaveBeenCalled();
    });

    it('should call highlightFeatures when breakpoint is lg', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('lg');

      initHighlightOrder(highlightOrder);
      expect(bp.getBreakpointSize).toHaveBeenCalled();
      expect(highlightOrder.find).toHaveBeenCalled();
    });
  });
});
