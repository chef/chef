
require 'chef/index_queue/amqp_client'
$sync_library_go_count ||= 0
module SyncLibrary

  def go
    Chef::Log.info('First generation library')

    # Publish the first run
    $sync_library_go_count += 1
    if $sync_library_go_count < 2
      amqp  = Chef::IndexQueue::AmqpClient.instance
      queue = amqp.amqp_client.queue('sync_library_test')
      queue.publish("first run complete")

      # Wait until the message is consumed / the sync_library cookbook is updated
      mcount = 1
      while mcount > 0
        Chef::Log.info("Sleeping while message is being consumed")
        sleep 1
        mcount = queue.message_count
      end
    end

  end

end