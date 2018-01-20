describe 'Auth jobs', auth_helpers: true, site: :org, api_version: :v1, set_app: true do
  let(:user) { FactoryBot.create(:user) }
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }
  let(:job)  { repo.builds.first.matrix.first }

  # accesses the logs api for the job's log
  let(:log_url) { "#{Travis.config[:logs_api][:url]}/logs/#{job.id}?by=job_id&source=api" }
  before { stub_request(:get, log_url).to_return(status: 200, body: %({"job_id": #{job.id}, "content": "content"})) }
  before { Job.update_all(state: :started) }

  # TODO
  # post '/jobs/:id/cancel'
  # post '/jobs/:id/restart'
  # patch '/jobs/:id/log'

  describe 'in private mode, with a private repo', mode: :private, repo: :private do
    describe 'GET /jobs' do
      it(:with_permission)    { should auth status: 200, empty: false }
      it(:without_permission) { should auth status: 200, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, empty: true } # was 401, i think this is acceptable
    end

    describe 'GET /jobs/%{job.id}' do
      it(:with_permission)    { should auth status: 200, empty: false }
      it(:without_permission) { should auth status: 302 } # redirects to /repositories/jobs/%{job.id}
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 302 } # was 401, probably acceptable?
    end

    describe 'GET /jobs/%{job.id}/log' do
      it(:with_permission)    { should auth status: 200, empty: false }
      xit(:without_permission) { should auth status: 404 } # TODO not ok
      it(:invalid_token)      { should auth status: 403 }
      xit(:unauthenticated)    { should auth status: 401 } # TODO not ok
    end
  end



  # +-------------------------------------------------------------+
  # |                                                             |
  # |   !!! BELOW IS THE ORIGINAL BEHAVIOUR ... DON'T TOUCH !!!   |
  # |                                                             |
  # +-------------------------------------------------------------+

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /jobs' do
      it(:with_permission)    { should auth status: 200, empty: false }
      it(:without_permission) { should auth status: 200, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, empty: false }
    end

    describe 'GET /jobs/%{job.id}' do
      it(:with_permission)    { should auth status: 200, empty: false }
      it(:without_permission) { should auth status: 200, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, empty: false }
    end

    describe 'GET /jobs/%{job.id}/log' do
      it(:with_permission)    { should auth status: 200, empty: false }
      it(:without_permission) { should auth status: 200, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, empty: false }
    end
  end
end
