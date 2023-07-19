import type { IconType } from "react-icons";
import { BsMicrosoftTeams } from "react-icons/bs";
import { SiMicrosoftsharepoint } from "react-icons/si";
import { FaUserCircle, FaGraduationCap, FaBookReader } from "react-icons/fa";
type socialLinksType = {
  color: string;
  icon: IconType;
  url: string;
  label: string;
};
export const socialLinksData: socialLinksType[] = [
  {
    color: "social.msteams",
    icon: BsMicrosoftTeams,
    label: "Microsoft Teams",
    url: "https://teams.microsoft.com/share?href=https%3A%2F%2Fapp.powerbi.com%2Fgroups%2Fme%2Fapps%2Ffa4a5294-f51a-4515-938c-86d005f16bc3%2Freports%2Fbf37e89a-5243-443d-bee9-e79a5f60525e%2FReportSection135437372e0119707bd0%3Faction%3DOpenReport%26pbi_source%3DChatInTeams%26bookmarkGuid%3D03f61c54-69ed-4500-b3d2-28fbcd6b3dd0",
  },
  {
    color: "social.msSharepoint",
    icon: SiMicrosoftsharepoint,
    label: "Microsoft sharepoint",
    url: "https://loreal.sharepoint.com/sites/VALUECockpit",
  },
  {
    color: "social.support",
    icon: FaUserCircle,
    label: "support",
    url: "https://loreal.service-now.com/myservices?id=nr_sc_cat_item&sys_id=eaf74874db6aa3409144453f29961969&sysparm_variables=%7B%22cmdb_ci%22:%22c66cb6771b5fc5d4278b41939b4bcbc7%22%7D",
  },
  {
    color: "grey",
    icon: FaGraduationCap,
    label: "E-learning",
    url: "https://loreal.sharepoint.com/sites/VALUECockpit/SitePages/USER-GUIDES.aspx?xsdata=MDV8MDF8fDIxYWYyNWFhMGZlNTQ5YjliM2M5MDhkYWZhNjdhMWZifGU0ZTFhYmQ5ZWFjNzRhNzFhYjUyZGE1Yzk5OGFhN2JhfDB8MHw2MzgwOTc2MjAyMzI1NDkzMjF8VW5rbm93bnxWR1ZoYlhOVFpXTjFjbWwwZVZObGNuWnBZMlY4ZXlKV0lqb2lNQzR3TGpBd01EQWlMQ0pRSWpvaVYybHVNeklpTENKQlRpSTZJazkwYUdWeUlpd2lWMVFpT2pFeGZRPT18MXxNVFkzTkRFMk5USXlNalE1T1RzeE5qYzBNVFkxTWpJeU5EazVPekU1T2pBNE56Rm1aR0prTFRKaE5tUXRORFl5WlMwNVpUWmhMVEF6WVdNeVpqRm1ZamRtTWw4eE56Y3dOMkUzWVMwd1pETTBMVFEzTm1NdFltTTBZUzFtTVdZek1qbGxNVEUxT0RWQWRXNXhMbWRpYkM1emNHRmpaWE09fDA2YjgxZmVjMzIwZDQ2MDJiM2M5MDhkYWZhNjdhMWZifDNjNTVkODg1ZDY2NzQyZGRiZDg4ZjJhY2QwYjc0NmIz&sdata=NzRSc1ZUYjA4THZ4Vkd3RnpSWlk3bzJQOHdxUzRicDM3VGJNWFFqU3ozWT0%3D&ovuser=e4e1abd9-eac7-4a71-ab52-da5c998aa7ba%2Cali.rizk%40loreal.com&OR=Teams-HL&CT=1674165457057&clickparams=eyJBcHBOYW1lIjoiVGVhbXMtRGVza3RvcCIsIkFwcFZlcnNpb24iOiIyNy8yMzAxMDUwNTYwMCIsIkhhc0ZlZGVyYXRlZFVzZXIiOmZhbHNlfQ%3D%3D",
  },
  {
    color: "grey",
    icon: FaBookReader,
    label: "Glossary",
    url: "https://loreal.sharepoint.com/sites/VALUECockpit/Lists/Glossary/AllItems.aspx?as=json",
  },
];
