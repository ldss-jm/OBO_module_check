#
# tested in ruby 2.3.3 and jruby 1.7.26
#
# this does not rigorously check 830s for proper formatting, but I found
# no cases of bad 830 formatting in 2016 records.
#
# One could try to manually scrape the list of owned modules (from
# the intranet or master coll xls) and/or the list of subject update files
# from the OBO site, but I'm not sure either is worth the effort.
# If there are changes to which subject modules we own, the hardcoded
# list below needs to be updated.


# Usage:
#   ruby obo_module_check.rb

# Input:
# This operates on all the *.mrc files in the current directory, with
# separate output files for each.

# Output:
# filename_owned.mrc :
#              .mrc file with records for owned modules. Deleted if
#              there are none.
# filename_unowned.mrc :
#              .mrc file with records for unowned module. Deleted if
#              there are none.
# filename_MODULE_PROBLEMS.txt:
#              text file containing a list of unowned modules followed
#              by a list of owned modules with 0 records in the input
#              .mrc file
#

require 'fileutils'
require 'marc'

def make_773_from_830(value)
  _773 = (value.gsub('Oxford bibliographies online. ', 'Oxford bibliographies online (online collection). ')
     .gsub('Oxford bibliographies. ', 'Oxford bibliographies online (online collection). ')
     .sub(/\. ?$/,'')
     .downcase)
  return _773
end

ownedmodules = ['Oxford bibliographies online (online collection). African American studies',
'Oxford bibliographies online (online collection). African studies',
'Oxford bibliographies online (online collection). American literature',
'Oxford bibliographies online (online collection). Anthropology',
'Oxford bibliographies online (online collection). Art history',
'Oxford bibliographies online (online collection). Atlantic history',
'Oxford bibliographies online (online collection). Biblical studies',
'Oxford bibliographies online (online collection). British and Irish literature',
'Oxford bibliographies online (online collection). Buddhism',
'Oxford bibliographies online (online collection). Childhood studies',
'Oxford bibliographies online (online collection). Chinese studies',
'Oxford bibliographies online (online collection). Cinema and Media studies',
'Oxford bibliographies online (online collection). Classics',
'Oxford bibliographies online (online collection). Communication',
'Oxford bibliographies online (online collection). Criminology',
'Oxford bibliographies online (online collection). Ecology',
'Oxford bibliographies online (online collection). Education',
'Oxford bibliographies online (online collection). Environmental science',
'Oxford bibliographies online (online collection). Evolutionary biology',
'Oxford bibliographies online (online collection). Geography',
'Oxford bibliographies online (online collection). Hinduism',
'Oxford bibliographies online (online collection). International law',
'Oxford bibliographies online (online collection). International relations',
'Oxford bibliographies online (online collection). Islamic studies',
'Oxford bibliographies online (online collection). Jewish studies',
'Oxford bibliographies online (online collection). Latin American studies',
'Oxford bibliographies online (online collection). Latino studies',
'Oxford bibliographies online (online collection). Linguistics',
'Oxford bibliographies online (online collection). Literary and critical theory',
'Oxford bibliographies online (online collection). Management',
'Oxford bibliographies online (online collection). Medieval studies',
'Oxford bibliographies online (online collection). Military history',
'Oxford bibliographies online (online collection). Music',
'Oxford bibliographies online (online collection). Philosophy',
'Oxford bibliographies online (online collection). Political science',
'Oxford bibliographies online (online collection). Psychology',
'Oxford bibliographies online (online collection). Public health',
'Oxford bibliographies online (online collection). Renaissance and reformation',
'Oxford bibliographies online (online collection). Social work',
'Oxford bibliographies online (online collection). Sociology',
'Oxford bibliographies online (online collection). Victorian literature']
ownedmodules.map!(&:downcase)  


mrcfiles = Dir.glob('*.mrc')

mrcfiles.each do |mrcfile|
  ownedfile = mrcfile.sub(/.mrc$/, '_owned.mrc')
  unownedfile = mrcfile.sub(/.mrc$/, '_unowned.mrc')
  problemfile = mrcfile.sub(/.mrc$/, '_MODULE_PROBLEMS.txt')
  
  owned_writer = MARC::Writer.new(ownedfile)
  unowned_writer = MARC::Writer.new(unownedfile)
  
  seenmodules = []
  owned = []
  unowned = []
  MARC::Reader.new(mrcfile).each do |rec|
    # raise exception if there is not exactly 1 830
    if not rec.fields('830').length == 1
      raise 'Found a record that does not have exactly 1 830'
    end
    _773 = make_773_from_830(rec['830'].value)
    if not seenmodules.include?(_773)
      seenmodules << _773
    end
    if ownedmodules.include?(_773)
      owned << rec
      owned_writer.write(rec)
    else
      unowned << rec
      unowned_writer.write(rec)
    end
  end
  
  test = []
  MARC::Reader.new(mrcfile).each do |rec|
    test << rec
  end
  
  
  owned_writer.close()
  unowned_writer.close()
  
  #delete either of these mrc files with no recs
  if owned.empty?
    FileUtils.rm(ownedfile)
  end
  if unowned.empty?
    FileUtils.rm(unownedfile)
  end
  
  
  seen_unowned = []
  owned_unseen = []
  #verify unowned
  puts "\n" + mrcfile
  puts "Unowned modules with records present:"
  seenmodules.each do |seen|
    if not ownedmodules.include?(seen)
      puts seen
      seen_unowned << seen
    end
  end
  if seen_unowned.empty?
    puts 'No such modules'
  end
  
  #verify 0 okay
  puts "\nOwned modules with no records:"
  ownedmodules.each do |owned|
    if not seenmodules.include?(owned)
      puts owned
      owned_unseen << owned
    end
  end
  if owned_unseen.empty?
    puts 'No such modules'
  end
  puts "\n\n"
  
  #write issues to file:
  File.open(problemfile, 'w') do |file|
    file.write('Potentially unowned modules found in MARC. These
  records were excluded from the "owned" mrc file. Verify that these are
  unowned modules on intranet?:
  https://intranet.lib.unc.edu/wikis/staff/index.php/Oxford_bibliographies_online_batch_edits#773s_established
  Unowned modules present:' + "\r\n")
    if seen_unowned.empty?
      file.write('***None!')
    else
      seen_unowned.each do |subjmodule|
        file.write('***' + subjmodule + "\r\n")
      end
    end
    file.write("\r\n\r\n")
    file.write('Owned modules with no records found in MARC update. Check
  website to make sure these modules aren\'t listed as having updates
  on the OSO website:
      http://www.oxfordbibliographies.com/page/408/Marc-records-by-update              
  If the module is listed on the website, download the subject file and
  combine them with the All Subjects file, and notify OUP they need to add
  that subject to the All Subjects file. Until this script is trusted, it
  might be best to doublecheck that the module isn\'t in the All Subjects
  file first.' + "\r\n")
    if owned_unseen.empty?
      file.write('***None!')
    else
      owned_unseen.each do |subjmodule|
        file.write('***' + subjmodule + "\r\n")
      end
    end
  end
end

puts 'Press enter to close this window.'
gets
exit()
