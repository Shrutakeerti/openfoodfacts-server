#!/usr/bin/perl -w

use ProductOpener::PerlStandards;

use Test::More;
use ProductOpener::APITest qw/:all/;
use ProductOpener::Test qw/:all/;
use ProductOpener::TestDefaults qw/:all/;

use File::Basename "dirname";

use Storable qw(dclone);

remove_all_users();

remove_all_products();

wait_application_ready();

# Create an admin
my $admin_ua = new_client();
my $resp = create_user($admin_ua, \%admin_user_form);
ok(!html_displays_error($resp));

# Create a normal user
my $ua = new_client();
my %create_user_args = (%default_user_form, (email => 'bob@gmail.com'));
$resp = create_user($ua, \%create_user_args);
ok(!html_displays_error($resp));

# Create a moderator
my $moderator_ua = new_client();
$resp = create_user($moderator_ua, \%moderator_user_form);
ok(!html_displays_error($resp));

# Admin gives moderator status
my %moderator_edit_form = (
	%moderator_user_form,
	user_group_moderator => "1",
	type => "edit",
);
$resp = edit_user($admin_ua, \%moderator_edit_form);
ok(!html_displays_error($resp));

# Note: expected results are stored in json files, see execute_api_tests
my $tests_ref = [

	# Create a product
	{
		test_case => 'create-product',
		method => 'PATCH',
		path => '/api/v3/product/1234567890100',
		body => '{
			"product": {
				"product_name_en": "Test product",
				"brands_tags": ["Test brand"],
				"categories_tags": ["en:beverages", "en:teas"],
				"lang": "en",
				"countries_tags": ["en:france"]
			}
		}',
	},
	# Update the product
	{
		test_case => 'update-product',
		method => 'PATCH',
		path => '/api/v3/product/1234567890100',
		body => '{
			"fields" : "updated",
			"product": { 
				"product_name_en": "Test product updated",
				"brands_tags": ["Test brand updated"],
				"categories_tags": ["en:coffees"],
				"countries_tags": ["en:france"]
			}
		}',
	},
	# Revert the product - good (existing code and rev + moderator user)
	{
		test_case => 'revert-product-good',
		method => 'POST',
		path => '/api/v3/product_revert',
		body => '{
			"code": "1234567890100",
			"rev": 1,
			"fields": "code,rev,product_name_en,brands_tags,categories_tags"
		}',
		ua => $moderator_ua,
	},
];

execute_api_tests(__FILE__, $tests_ref);

done_testing();
