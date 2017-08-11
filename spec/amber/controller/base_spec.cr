require "../../../spec_helper"

module Amber::Controller
  describe Base do
    describe "#cookies" do
      it "responds to cookies" do
        controller = build_controller

        controller.responds_to?(:cookies).should eq true
      end
    end

    describe "#session" do
      it "responds to cookies" do
        controller = build_controller

        controller.responds_to?(:session).should eq true
      end

      it "sets a session value" do
        controller = build_controller

        controller.session["name"] = "David"

        controller.session["name"].should eq "David"
      end

      it "has a session id" do
        controller = build_controller

        controller.session.id.not_nil!.size.should eq 36
      end
    end

    describe "#render" do
      it "renders html from slang template" do
        request = HTTP::Request.new("GET", "/?test=test")
        context = create_context(request)
        html_output = <<-HTML
        <h1>Hello World</h1>\n<p>I am glad you came</p>
        HTML

        TestController.new(context).render_template_page.should eq html_output
      end

      it "renders partial without layout" do
        request = HTTP::Request.new("GET", "/?test=test")
        context = create_context(request)
        html_output = <<-HTML
        <h1>Hello World</h1>
        <p>I am glad you came</p>
        HTML

        TestController.new(context).render_partial.should eq html_output
      end

      it "renders flash message" do
        request = HTTP::Request.new("GET", "/")
        context = create_context(request)

        controller = TestController.new(context)

        controller.render_with_flash
      end

      it "renders html and layout from slang template" do
        request = HTTP::Request.new("GET", "/?test=test")
        context = create_context(request)
        html_output = <<-HTML
        <html>\n  <body>\n    <h1>Hello World</h1>\n<p>I am glad you came</p>\n  </body>\n</html>
        HTML

        TestController.new(context).render_with_layout.should eq html_output
      end

      it "renders a form with a csrf tag" do
        request = HTTP::Request.new("GET", "/?test=test")
        context = create_context(request)
        csrf_token = Amber::Pipe::CSRF.token(context)
        html_output = <<-HTML
        <form action="/posts" method="post">
          <input type="hidden" name="_csrf" value="#{csrf_token}" />
          <div class="form-group">
            <input class="form-control" type="text" name="title" placeholder="Title" value="hey you">
          </div>
          <div class="form-group">
            <textarea class="form-control" rows="10" name="content" placeholder="Content">out there in the cold</textarea>
          </div>
          <button class="btn btn-primary btn-xs" type="submit">Submit</button>
          <a class="btn btn-default btn-xs" href="/posts">back</a>
        </form>
        HTML

        TestController.new(context).render_with_csrf.should eq html_output
      end
    end

    describe "#before_action" do
      context "registering action filters" do
        it "registers a before action" do
          controller = build_controller
          controller.before_filters

          before_filters = controller.filters[:before]

          before_filters.size.should eq 5
        end

        it "registers a after action" do
          controller = build_controller
          controller.after_filters

          after_filters = controller.filters[:after]

          after_filters.size.should eq 2
        end
      end

      context "running filters" do
        it "runs before filters" do
          controller = build_controller
          controller.run_before_filter(:index)

          controller.total.should eq 4
        end

        it "runs after filters" do
          controller = build_controller
          controller.run_after_filter(:index)

          controller.total.should eq 2
        end
      end
    end

    describe "#redirect_back" do
      context "and has a valid referer" do
        it "sets the correct response headers" do
          controller = build_controller("/world")

          controller.redirect_back
          response = controller.response

          response.headers["Location"].should eq "/world"
        end
      end

      context "and does not have a referer" do
        it "halts the requests and sets context.content" do
          controller = build_controller("")
          controller.redirect_back

          context = controller.context

          context.content.should eq "Redirecting to /"
          context.halt.should eq true
        end
      end
    end

    describe "#redirect_to" do
      context "with url params" do
        it "sets the url params to path" do
          controller = build_controller("/world")
          controller.redirect_to(:world, 302, {"hello" => "world"})

          response = controller.response

          response.headers["Location"].should eq "/hello/world?hello=world"
        end
      end

      context "whith flash" do
        it "sets the flash scope from Hash(Symbol, String)" do
          controller = build_controller("")
          query = {} of String => String
          controller.redirect_to(:world, 302, query, {:notice => "Success!"})

          flash = controller.flash

          flash["notice"].should eq "Success!"
        end

        it "sets the flash scope from Hash(String, String)" do
          controller = build_controller("")
          query = {} of String => String
          controller.redirect_to(:world, 302, query, {"notice" => "Success!"})

          flash = controller.flash

          flash["notice"].should eq "Success!"
        end
      end

      context "when redirecting to url or path" do
        ["www.amberio.com", "/world"].each do |location|
          it "sets the location to #{location}" do
            controller = build_controller
            controller.redirect_to(location, 301)

            response = controller.response

            response.headers["Location"].should eq location
            response.status_code.should eq 301
          end
        end
      end

      context "with invalid url or path" do
        it "raises redirect error" do
          controller = build_controller

          controller.redirect_to "saasd"
        end
      end

      context "when redirecting to controller action" do
        it "sets the controller and action" do
          controller = build_controller
          controller.redirect_to :world, 301

          response = controller.response

          response.headers["Location"].should eq "/hello/world"
          response.status_code.should eq 301
        end
      end

      context "when redirecting to different controller" do
        it "sets new controller and action" do
          controller = build_controller
          controller.redirect_to :index, :hello, 301

          response = controller.response

          response.headers["Location"].should eq "/hello/index"
          response.status_code.should eq 301
        end
      end

      context "#halt!" do
        it "sets context halt to true" do
          controller = build_controller

          controller.halt!
          context = controller.context

          context.content.should eq ""
        end

        it "set response status code" do
          controller = build_controller

          controller.halt!(status_code = 900)
          context = controller.context

          context.response.status_code.should eq 900
        end
      end
    end
  end
end
