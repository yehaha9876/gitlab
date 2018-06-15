require 'spec_helper'

describe PropagateServiceTemplateWorker do
  let!(:service_template) do
    PushoverService.create(
      template: true,
      active: true,
      properties: {
        device: 'MyDevice',
        sound: 'mic',
        priority: 4,
        user_key: 'asdf',
        api_key: '123456789'
      })
  end

  before do
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain)
      .and_return(true)
  end

  describe '#perform' do
    it 'calls the propagate service with the template' do
      expect(Projects::PropagateServiceTemplate).to receive(:propagate).with(service_template)

      subject.perform(service_template.id)
    end

    it 'silently ignores error when lease could not be obtained' do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(nil)

      subject.perform(service_template.id)
    end
  end
end
