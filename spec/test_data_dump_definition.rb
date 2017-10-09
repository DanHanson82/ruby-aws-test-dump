# test data to be dumped and restored for tests defined here

DATA_DUMP_DEFINITIONS = [
  {
    table_name: 'some_table_name',
    key_conditions: {
      'user_name' => {
        :attribute_value_list => ['chorizo'],
        :comparison_operator => 'EQ'
      }
    },
    replace_first: {
      'user_name' => 'chorizo',
    }
  },
  {
    table_name: 'some_other_table',
    key_conditions: {
      'another_id' => {
        :attribute_value_list => ['fake'],
        :comparison_operator => 'EQ'
      },
      'user_email' => {
        :attribute_value_list => ['bob@bob.com'],
        :comparison_operator => 'EQ'
      }
    },
    replace_these: {
      'user_email' => 'bob@bob.com',
    },
    replace_first: {
      'another_id' => 'fake',
      'customer_id' => 'fake_id',
    }
  }
]
